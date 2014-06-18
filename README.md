Copy Basecamp projects from one account to another.

![Photocopier](https://help.github.com/assets/help/fork-a-repo-e50d51c694939c58b2f83c58fc679c4e.gif)

Usage:
------
    
Put the following in `.secrets.yml`:
```
---
dry_run: true # set to false to actually copy data to target project
from_account: 123456
from_user: bob
from_pass: str0ng
to_account: 654321
to_user: corporatebob
to_pass: r3ally!str0ng
```

Then:

    ./bcx-project-photocopier.rb from_project_id to_project_id

Not yet implemented (feel free to pull req):

 * preserving original authorship (would require user/pass for everyone?)
 * copying accesses/subscriptions
 * copying events
 * copying file labels (not even in the API?)
 * copying stars

Why?

> We don't have a way to move projects from one account into another. I'm sorry, I know that's frustrating. There's actually a good reason behind it though. It means people can't 'steal' projects, and lock them away in another account on you. 
> 
> The account owner can make an export of those projects, though, using the link on the Account page. This isn't importable, but it can make it easier to manually add the data to the new account.

I'm still not quite sure I understand the reasoning behind not allowing it, I'll admit.

LICENSE
-------
Copyright (c) 2014, Ryan Baumann
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Notes:
------
```
from account
to account

All URLs start with https://basecamp.com/999999999/api/v1/. SSL only. The path is prefixed with the account id and the API version. If we change the API in backward-incompatible ways, we'll bump the version marker and maintain stable support for the old URLs.

GET /projects.json will return all active projects.

for each project
  GET /projects/1.json will return the specified project.

  create project on to account
    POST /projects.json will create a new project from the parameters passed.

    for each todo list
      GET /projects/1/todolists.json shows active todolists for this project sorted by position.
      GET /projects/1/todolists/completed.json shows completed todolists for this project.

      GET /projects/1/todolists/1.json will return the specified todolist including the todos.

      create todo list on to account
        POST /projects/1/todolists.json will create a new todolist from the parameters passed.

      for each comment
        POST /projects/1/<section>/1/comments.json will create a new comment from the parameters passed for the commentable described via / -- for example /projects/1/messages/1/comments.json or /projects/1/todos/1/comments.json. The subscribers array is an optional list of people IDs that you want to notify about this comment (see Get accesses on how to get the people IDs for a given project).
    for each document
      GET /projects/1/documents.json shows documents for this project ordered alphabetically by title.
      GET /projects/1/documents/1.json will return the specified document along with all comments.

      create document on to account
        POST /projects/1/documents.json will create a new document from the parameters passed.

      for each comment
    for each topic
      GET /projects/1/topics.json shows topics for this project. We will return 50 topics per page. If the result set has 50 topics, it's your responsibility to check the next page to see if there are any more topics -- you do this by adding &page=2 to the query, then &page=3 and so on.

      for each message
        GET /projects/1/messages/1.json will return the specified message.

        download attachments
          GET /projects/1/attachments/1.json will return the specified attachment with file metadata, urls, and associated attachables (Uploads, Messages, or Comments) with a 200 OK response.

        create attachments
          POST /attachments.json uploads a file. The request body should be the binary data of the attachment. Make sure to set the Content-Type and Content-Length headers.

        create message on to account
          POST /projects/1/messages.json will create a new message from the parameters passed. The subscribers array is an optional list of people IDs that you want to notify about this comment (see Get accesses on how to get the people IDs for a given project).

          for each comment
      for each upload
        GET /projects/1/uploads/2.json will show the content, comments, and attachments for this upload.

        download attachment
          GET /projects/1/attachments/1.json will return the specified attachment with file metadata, urls, and associated attachables (Uploads, Messages, or Comments) with a 200 OK response.

        create attachment
          POST /attachments.json uploads a file. The request body should be the binary data of the attachment. Make sure to set the Content-Type and Content-Length headers.

        create upload on to account
          POST /projects/1/uploads.json will create a new entry in the "Files" section on the given project, with the given attachment token.

        for each comment
    for each access
      GET /projects/1/accesses.json will return all the people with access to the project.

      create access on to account
        POST /projects/1/accesses.json will grant access to the project for the existing ids of people already on the account or new people via email_addresses. (Same goes for calendars with /calendars/ instead)
```