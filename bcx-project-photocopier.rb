#!/usr/bin/env ruby

require 'net/http'
require 'net/https'
require 'json'
require 'yaml'
require 'pp'

$config = YAML.load_file('.secrets.yml')
$dry_run = true

def api_url(account, path, params = '')
  return "https://basecamp.com/#{account}/api/v1/#{path}.json#{params}"
end

def authenticated_request(url)
  uri = URI(url)

  Net::HTTP.start(uri.host, uri.port,
    :use_ssl => uri.scheme = 'https',
    :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

    request = Net::HTTP::Get.new(uri.request_uri, {'Content-Type' => 'application/json', 'User-Agent' => 'bcx-project-photocopier (ryan.baumann@gmail.com)'})
    request.basic_auth $config['from_user'], $config['from_pass']

    response = http.request request # Net::HTTPResponse object
    sleep(0.02) # 500 req/10s

    $stderr.puts response.inspect
    return response.body
  end
end

def authenticated_post(account, path, data)
  $stderr.puts api_url(account, path)

  uri = URI(api_url(account, path))

  unless $dry_run
    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme = 'https',
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

      request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'application/json', 'Content-Length' => data.length.to_s, 'User-Agent' => 'bcx-project-photocopier (ryan.baumann@gmail.com)'})
      request.basic_auth $config['to_user'], $config['to_pass']
      request.body = data

      response = http.request request # Net::HTTPResponse object
      sleep(0.02) # 500 req/10s

      $stderr.puts response.inspect
      return JSON.parse(response.body)
    end
  end
end

def create_attachment(account, project, data, content_type, content_length)
  uri = URI(api_url(account, "projects/#{project}/attachments"))

  if $dry_run
    return {"token" => "abcdef1234567890"}
  else
    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme = 'https',
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

      request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => content_type, 'Content-Length' => content_length.to_s, 'User-Agent' => 'bcx-project-photocopier (ryan.baumann@gmail.com)'})
      request.basic_auth $config['to_user'], $config['to_pass']
      request.body = data

      response = http.request request # Net::HTTPResponse object
      sleep(0.02) # 500 req/10s

      $stderr.puts response.inspect
      return JSON.parse(response.body)
    end
  end
end

def copy_attachment(attachment, to_project_id)
  attachment_data = authenticated_request(attachment["url"])
  return create_attachment($config['to_account'], to_project_id, attachment_data, attachment["content_type"], attachment["byte_size"])
end

def copy_comment(comment, to_project_id, to_path)
  attachments = comment["attachments"].collect do |attachment|
    token = copy_attachment(attachment, to_project_id)["token"]
    {
      "token" => token,
      "name" => attachment["name"]
    }
  end

  new_comment_hash = {
    "content" =>  (comment["content"] + "\n\n(copied from original comment by #{comment["creator"]["name"]})"),
    "attachments" => attachments
  }
  PP.pp new_comment_hash

  authenticated_post($config['to_account'], to_path, new_comment_hash.to_json)
end

def basecamp_request(account, path, params = '')
  $stderr.puts api_url(account, path, params)

  return JSON.parse(authenticated_request(api_url(account, path, params)))
end

from_project_id = ARGV[0]
to_project_id = ARGV[1]

from_project = basecamp_request($config['from_account'],"projects/#{from_project_id}")
PP.pp from_project

topics = []
page = 1
topics_page = basecamp_request($config['from_account'],"projects/#{from_project_id}/topics")
while topics_page.length == 50
  topics += topics_page
  page += 1
  topics_page = basecamp_request($config['from_account'],"projects/#{from_project_id}/topics","?page=#{page}")
end
topics += topics_page

PP.pp topics

message_topics = topics.select{ |t| t["topicable"]["type"] == "Message" }
message_topics.each do |message|
  full_message = basecamp_request($config['from_account'],"projects/#{from_project_id}/messages/#{message["topicable"]["id"]}")
  PP.pp full_message

  new_message_hash = {
    "subject" => full_message["subject"],
    "content" => (full_message["content"] + "\n\n(copied from original message by #{full_message["creator"]["name"]})")
  }
  new_message = authenticated_post($config['to_account'], "projects/#{to_project_id}/messages", new_message_hash.to_json)
  PP.pp new_message

  new_message_id = new_message.nil? ? 1 : new_message["id"]

  full_message["comments"].each do |comment|
    copy_comment(comment, to_project_id, "projects/#{to_project_id}/messages/#{new_message_id}/comments")
  end
end

todo_topics = topics.select{ |t| t["topicable"]["type"] == "Todo" }

attachments = []
page = 1
attachments_page = basecamp_request($config['from_account'],"projects/#{from_project_id}/attachments")
while attachments_page.length == 50
  attachments += attachments_page
  page += 1
  attachments_page = basecamp_request($config['from_account'],"projects/#{from_project_id}/attachments","?page=#{page}")
end
attachments += attachments_page

PP.pp attachments

todo_lists = basecamp_request($config['from_account'],"projects/#{from_project_id}/todolists")
todo_lists += basecamp_request($config['from_account'],"projects/#{from_project_id}/todolists/completed")
PP.pp todo_lists

todo_lists.each do |todo_list|
  todo_list = basecamp_request($config['from_account'],"projects/#{from_project_id}/todolists/#{todo_list["id"]}")
  PP.pp todo_list
  %w{remaining completed}.each do |todo_status|
    todo_list["todos"][todo_status].each do |todo|
      puts todo["content"]
    end
  end
end

documents = basecamp_request($config['from_account'],"projects/#{from_project_id}/documents")
documents.each do |document|
  document = basecamp_request($config['from_account'],"projects/#{from_project_id}/documents/#{document["id"]}")
  PP.pp document
end

uploads = attachments.select{ |a| a["attachable"]["type"] == "Upload" }
puts attachments.length
puts uploads.length

uploads.each do |upload|
  attachment = copy_attachment(upload, to_project_id)
  PP.pp attachment

  upload_content = basecamp_request($config['from_account'],"projects/#{from_project_id}/uploads/#{upload["attachable"]["id"]}")["content"]
  new_upload_hash = {
    "attachments" => [
      {
        "token" => attachment["token"],
        "name" => upload["name"]
      }
    ]
  }
  unless upload_content.nil?
    new_upload_hash["content"] = upload_content
  end
  PP.pp new_upload_hash

  new_upload = authenticated_post($config['to_account'], "projects/#{to_project_id}/uploads", new_upload_hash.to_json)
  PP.pp new_upload
end

accesses = basecamp_request($config['from_account'],"projects/#{from_project_id}/accesses")
PP.pp accesses