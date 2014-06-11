#!/usr/bin/env ruby

require 'net/http'
require 'net/https'
require 'json'
require 'yaml'
require 'pp'

$config = YAML.load_file('.secrets.yml')

def api_url(account, path, params = '')
  return "https://basecamp.com/#{account}/api/v1/#{path}.json#{params}"
end

def basecamp_request(account, path, params = '')
  $stderr.puts api_url(account, path, params)
  uri = URI(api_url(account, path, params))

  Net::HTTP.start(uri.host, uri.port,
    :use_ssl => uri.scheme = 'https',
    :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

    request = Net::HTTP::Get.new(uri.request_uri, {'Content-Type' => 'application/json', 'User-Agent' => 'bcx-project-photocopier (ryan.baumann@gmail.com)'})
    request.basic_auth $config['from_user'], $config['from_pass']

    response = http.request request # Net::HTTPResponse object
    sleep(0.02) # 500 req/10s

    $stderr.puts response.inspect
    return JSON.parse(response.body)
  end
end

from_project_id = ARGV[0]
# to_project_id = ARGV[1]

from_project = basecamp_request($config['from_account'],"projects/#{from_project_id}")
PP.pp from_project

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

accesses = basecamp_request($config['from_account'],"projects/#{from_project_id}/accesses")
PP.pp accesses