# This Project has been moved!

Development continues at https://github.com/audriga/jmap-cli

# jmap-cli

A command-line interface for interacting with **[JMAP](https://jmap.io/index.html) servers**, built on top of (our fork of) [JMAP Dart client library](https://github.com/audriga/jmap-dart-client).
We use this tool, to test our fork of the client library.
We mainly test against [Stalwart](https://github.com/stalwartlabs/stalwart).
See [jmap-dart-client/FORK#jmap-servers](https://bitbucket.org/audriga/jmap-dart-client/src/master/FORK.md#jmap-servers) for other jmap servers we tested against.

For more information on JMAP, see also [the JMAP Crash Course](https://jmap.io/crash-course.html)

<!-- TOC -->
* [jmap-cli](#jmap-cli)
    * [Running the CLI Tool](#running-the-cli-tool)
  * [Features](#features)
    * [Supported Sub-Commands](#supported-sub-commands)
    * [Global Options](#global-options)
      * [Show global help](#show-global-help)
      * [Show help for a specific command](#show-help-for-a-specific-command)
  * [Session](#session)
    * [session get](#session-get)
  * [Identity](#identity)
    * [identity get](#identity-get)
  * [AddressBook](#addressbook-)
    * [addressBook create](#addressbook-create)
    * [addressBook get](#addressbook-get)
    * [addressBook delete](#addressbook-delete)
    * [addressBook changes](#addressbook-changes)
  * [Contacts](#contacts)
    * [Support for Legacy Contact Spec](#support-for-legacy-contact-spec)
    * [contact create](#contact-create)
    * [contact delete](#contact-delete)
    * [contact get](#contact-get)
    * [contact changes](#contact-changes)
  * [Calendar](#calendar-)
    * [calendar create](#calendar-create)
    * [calendar get](#calendar-get)
    * [calendar delete](#calendar-delete)
    * [calendar changes](#calendar-changes)
  * [Calendar Events](#calendar-events)
    * [calendarEvent create](#calendarevent-create)
    * [calendarEvent get](#calendarevent-get)
    * [calendarEvent delete](#calendarevent-delete)
    * [calendarEvent changes](#calendarevent-changes)
  * [Email](#email)
    * [email get](#email-get)
    * [email create](#email-create)
    * [email delete](#email-delete)
    * [email send](#email-send)
    * [email query](#email-query)
    * [email changes](#email-changes)
  * [Mailbox](#mailbox)
    * [mailbox get](#mailbox-get)
    * [mailbox create](#mailbox-create)
    * [mailbox delete](#mailbox-delete)
    * [mailbox changes](#mailbox-changes)
  * [FileNodes](#filenodes)
    * [fileNodes list](#filenodes-list)
    * [fileNodes tree](#filenodes-tree)
    * [fileNodes mkdir](#filenodes-mkdir)
    * [fileNodes rm](#filenodes-rm)
    * [fileNodes cp](#filenodes-cp)
* [License](#license)
* [Acknowledgement](#acknowledgement)
<!-- TOC -->

### Running the CLI Tool

- **Before Running:**
  - Download flutter, see [the flutter quickstart](https://docs.flutter.dev/install/quick)
    - Note: We use flutter instead of pure dart as a dependency for integration tests.
  - Execute `flutter pub get` in the root directory of this repository to install dependencies.
- **Build the Executable:**
```bash
dart compile exe bin/jmap_cli.dart -o bin/jmap_cli
```
This produces a self-contained executable which can be used on other machines (that don't have flutter or dart installed) as-is.
Dart supports Linux/ Windows/ MacOS. The above command does not depend on your operating system.

## Features

* We support the jmap functions `/get` `/set`, and `/changes` for Contacts, AddressBooks, CalendarEvents, Calendars, Emails, Mailboxes, and FileNodes.
* For Emails we additionally support `/query` for filtering and paging, `/import` for storing raw MIME messages, and `EmailSubmission/set` for sending.
* In the FileNode case we support (mostly) rsync-inspired file management operations.

### Supported Sub-Commands

The general command structure is
`jmap_cli <objectType> <operation>`, where `<objectType> is one of the following:

* `addressBook`
* `contact`
* `calendar`
* `calendarEvent`
* `email`
* `fileNodes`
* `identity`
* `mailbox`
* `session`

The available operations depend on the object type (and will be explained in their corresponding section), but common ones are
* `get` gets all items ot the object type
* `create` creates an item
* `delete` deletes an item
* `changes` information on which items were created/ modified/ deleted since the given state-string

### Global Options
- `--url`               URL of the JMAP server  
- `--userName`, `-u`    Username used for authentication  
- `--userPassword`, `-p`  Password for authentication  
- `--accountId`, `-a`   Account id to operate on  
- `--id`, `-i`          Used by delete commands  
- `--verbose`, `-v`     Enable detailed logging  
- `--version`           Print the CLI version  
- `--help`              Show help  

#### Show global help
```bash
jmap_cli --help
```

#### Show help for a specific command
```bash
jmap_cli <command> --help
```

## Session

### session get
Retrieve server capabilities and authentication info.

Usage:
```bash
jmap_cli session get --url <server-url> -u <user> -p <pass>
```
## Identity

### identity get
Retrieve identity details for the current account.

Usage:
```bash
jmap_cli identity get --url <server-url> -u <user> -p <pass>
```
## AddressBook 

### addressBook create
Create AddressBook.

Options:
- `--name` : Name of addressBook

Usage example:
```bash
jmap_cli addressBook create --url <server-url> -u <user> -p <pass> --name "My AddressBook"
```

### addressBook get
List AddressBooks.

Usage:
```bash
jmap_cli addressBook get --url <server-url> -u <user> -p <pass>
```

### addressBook delete
Delete AddressBook by id.

Options:
- `--id` : id of addressBook to delete

Usage example:
```bash
jmap_cli addressBook delete --url <server-url> -u <user> -p <pass> --id abc
```

### addressBook changes
Detect AddressBook changes.

Options:
- `--state` : If omitted, the CLI fetches the latest state
  
Usage example:
```bash
jmap_cli addressBook delete --url <server-url> -u <user> -p <pass> --state xyz
```

## Contacts

### Support for Legacy Contact Spec

For historic reasons, we support not only the current ietf draft spec for contacts, but two other versions as well (which will get removed in the future).
See [jmap-dart-client/ContactAPIVersions.md](https://bitbucket.org/audriga/jmap-dart-client/src/master/ContactAPIVersions.md) for more details
If you are interacting with a server that implements one of these legacy versions, you must set the corresponding flag.

```bash
--apiVersion <value>
```

Supported values:
- `ietf` (default)
- `cyrus`
- `jscontact`

### contact create
Create a contact.

Options:
- `--file`, `-f` : JSON file  
- `--fullName`  full name of Contact (supply either full name or json file)
- `--addressBookIds`, `-b` : Mandatory (except for legacy case where `--apiVersion jscontact`)
- `--apiVersion` : `ietf` (default), `cyrus`, `jscontact`

Usage example:
```bash
jmap_cli contact create --url <server-url> -u <user> -p <pass> --fullName "John Doe" --addressBookIds default --apiVersion ietf
```

Alternative usage example with a JSON file:
```bash
jmap_cli contact create --url <server-url> -u <user> -p <pass>  -f path/to/Contact.json --apiVersion jscontact
```
### contact delete
Delete a contact.

Options:
- `--id` : Id of Contact to delete

Usage example:
```bash
jmap_cli contact delete --url <server-url> -u <user> -p <pass>  -i xyz
```

### contact get
Fetch or list contacts.

Usage:
```bash
jmap_cli contact get --url <server-url> -u <user> -p <pass>
```

### contact changes
Fetch Contact changes since previous state.

Options:
- `--state`: If omitted, the CLI fetches the latest state automatically

Usage example:
```bash
jmap_cli contact changes --url <server-url> -u <user> -p <pass> --state abc
```


## Calendar 
### calendar create
Create calendar.

Options:
- `--name` : Name of calendar

Usage example:
```bash
jmap_cli calendar create --url <server-url> -u <user> -p <pass> --name "My Calendar"
```

### calendar get
List calendars.

Usage:
```bash
jmap_cli calendar get --url <server-url> -u <user> -p <pass>
```

### calendar delete
Delete calendar by id.

Options:
- `--id` : Id of calendar to delete

Usage example:
```bash
jmap_cli calendar delete --url <server-url> -u <user> -p <pass> -i xyz
```

### calendar changes
Detect calendar changes.

Options:
- `--state` : If omitted, the CLI fetches the latest state

Usage example:
```bash
jmap_cli calendar changes --url <server-url> -u <user> -p <pass> -state abc
```

## Calendar Events

### calendarEvent create
Create calendar events.

Options:
- `--file`, `-f` : path to JSON file  
- `--title`, `-t` : event title  
- `--calendarIds` : calendar ids (mandatory)  
- `--start` : ISO 8601 timestamp (optional)  
- `--duration` : ISO 8601 duration (e.g., `PT1H`)  

Usage example:
```bash
jmap_cli calendarEvent create --url <server-url> -u <user> -p <pass> --title "event" --calendarIds default
```

Alternative usage example with JSON file:
```bash
jmap_cli calendarEvent create --url <server-url> -u <user> -p <pass> -f path/to/calendarEvent.json
```

### calendarEvent get
List events.

Usage:
```bash
jmap_cli calendarEvent get --url <server-url> -u <user> -p <pass>
```

### calendarEvent delete
Delete event by id.

Options:
- `--id` : id of calendar event to delete

Usage example:
```bash
jmap_cli calendarEvent delete --url <server-url> -u <user> -p <pass> -i xyz
```

### calendarEvent changes
Detect changes to calendarEvents.

Options:
- `--state` : If omitted, the CLI fetches the latest state

Usage example:
```bash
jmap_cli calendarEvent changes --url <server-url> -u <user> -p <pass> -state abc
```

## Email

### email get
Fetch all emails or a single email by id. Use `--all` for full paged retrieval. Use `-o out.eml` to download raw MIME.

Options:
- `--id`, `-i` : Id of email to fetch
- `--all` : Fetch all emails via paged queries
- `--mailboxId`, `-m` : Filter by mailbox id (required with `--all` on some servers)
- `--batchSize` : Number of emails per page when using `--all` (default: 50)
- `--output`, `-o` : Write output to a file. If the path ends in `.eml`, downloads raw MIME instead of JSON.

Usage examples:
```bash
jmap_cli email get --url <server-url> -u <user> -p <pass>
jmap_cli email get --url <server-url> -u <user> -p <pass> -i <emailId>
jmap_cli email get --url <server-url> -u <user> -p <pass> --all --mailboxId <mailboxId>
jmap_cli email get --url <server-url> -u <user> -p <pass> -i <emailId> -o out.eml
```

### email create
Create an email from CLI args or a file. `.eml` files are automatically imported via `Email/import`. JSON files use `Email/set`.

Options:
- `--file`, `-f` : Path to a JSON or `.eml` file
- `--mailboxId`, `-m` : Mailbox id to place the email in (required for `.eml` import)
- `--subject`, `-s` : Email subject
- `--from` : Sender email address
- `--to` : Recipient email address
- `--body`, `-b` : Plain-text body

Usage examples:
```bash
jmap_cli email create --url <server-url> -u <user> -p <pass> --from sender@example.com --to recipient@example.com --subject "Hello" --body "Hi" --mailboxId <mailboxId>
jmap_cli email create --url <server-url> -u <user> -p <pass> -f email.json --mailboxId <mailboxId>
jmap_cli email create --url <server-url> -u <user> -p <pass> -f message.eml --mailboxId <mailboxId>
```

### email delete
Delete an email by id.

Options:
- `--id`, `-i` : Id of email to delete

Usage example:
```bash
jmap_cli email delete --url <server-url> -u <user> -p <pass> -i <emailId>
```

### email send
Create a draft and submit it for delivery in one step via `Email/set` + `EmailSubmission/set`.

Options:
- `--from` : Sender email address
- `--to` : Recipient email address
- `--subject`, `-s` : Email subject
- `--body`, `-b` : Plain-text body
- `--mailboxId`, `-m` : Mailbox id for the draft
- `--identityId` : Identity id to send from (use `identity get` to find it)

Usage example:
```bash
jmap_cli email send --url <server-url> -u <user> -p <pass> --from sender@example.com --to recipient@example.com --subject "Hello" --body "Hi" --mailboxId <mailboxId> --identityId <identityId>
```

### email query
Query email ids with optional filtering and paging.

Options:
- `--mailboxId`, `-m` : Filter to emails in this mailbox
- `--limit`, `-l` : Maximum number of ids to return
- `--position` : Zero-based index of the first result (for paging)

Usage examples:
```bash
jmap_cli email query --url <server-url> -u <user> -p <pass> --mailboxId <mailboxId>
jmap_cli email query --url <server-url> -u <user> -p <pass> --mailboxId <mailboxId> --limit 10 --position 0
jmap_cli email query --url <server-url> -u <user> -p <pass> --mailboxId <mailboxId> --limit 10 --position 10
```

### email changes
Fetch email changes since a given state.

Options:
- `--state` : If omitted, the CLI fetches the latest state automatically

Usage example:
```bash
jmap_cli email changes --url <server-url> -u <user> -p <pass> --state <state>
```

## Mailbox

### mailbox get
Fetch all mailboxes or a single mailbox by id. Use `--all` for full paged retrieval.

Options:
- `--id`, `-i` : Id of mailbox to fetch
- `--all` : Fetch all mailboxes via paged queries

Usage examples:
```bash
jmap_cli mailbox get --url <server-url> -u <user> -p <pass>
jmap_cli mailbox get --url <server-url> -u <user> -p <pass> -i <mailboxId>
jmap_cli mailbox get --url <server-url> -u <user> -p <pass> --all
```

### mailbox create
Create a mailbox.

Options:
- `--name`, `-n` : Name of the mailbox
- `--parentId` : Id of the parent mailbox (for nested folders)

Usage examples:
```bash
jmap_cli mailbox create --url <server-url> -u <user> -p <pass> --name "My Folder"
jmap_cli mailbox create --url <server-url> -u <user> -p <pass> --name "Sub Folder" --parentId <parentId>
```

### mailbox delete
Delete a mailbox by id.

Options:
- `--id`, `-i` : Id of mailbox to delete

Usage example:
```bash
jmap_cli mailbox delete --url <server-url> -u <user> -p <pass> -i <mailboxId>
```

### mailbox changes
Fetch mailbox changes since a given state.

Options:
- `--state` : If omitted, the CLI fetches the latest state automatically

Usage example:
```bash
jmap_cli mailbox changes --url <server-url> -u <user> -p <pass> --state <state>
```

## FileNodes

Manage files and folders on the JMAP server.

### fileNodes list
List files and folders inside a directory (non-recursive).

Options:
- `--path` : Path of folder to list (default: `/`)

Usage example:
```bash
jmap_cli fileNodes list --url <server-url> -u <user> -p <pass> --path someFolder
```

### fileNodes tree
Show files and folders recursively, analog to the Unix `tree` command.

Options:
- `--path` : Root path to display (default: `/`)

Usage example:
```bash
jmap_cli fileNodes tree --url <server-url> -u <user> -p <pass> --path someFolder
```

### fileNodes mkdir
Create a directory on the server.

Parameter:
- `<path>`: Path of folder to create

Usage example:
```bash
jmap_cli fileNodes mkdir jmap:someFolder/NewFolder --url <server-url> -u <user> -p <pass>
```

### fileNodes rm
Delete a file or directory on the server.

Parameter:
- `<path>`: Path of file or folder to delete

**Options:**
- `--recursive`, `-r` : Delete folders and their contents


Usage example
```bash
jmap_cli fileNodes rm -r someFolder --url <server-url> -u <user> -p <pass>
```

[//]: # (Note, there currently is a bug, where not everything specified gets deleted in that case simply repeat the same command a couple of times. )

### fileNodes cp
Copy files between the local filesystem and JMAP FileNodes.

Parameters:
`<src> <dst>` source and destination paths.

Use the `jmap:` prefix to indicate remote paths.  
Exactly one of the source or destination must be a JMAP path.

Options:
- `--recursive`, `-r` : In case of folders recurse and also copy contents

Usage examples:

Upload a local file to the server:
```bash
jmap_cli fileNodes cp upload.txt jmap:someFolder/local.txt --url <server-url> -u <user> -p <pass>
```

Download a file from the server:
```bash
jmap_cli fileNodes cp jmap:someFolder/local.txt download.txt --url <server-url> -u <user> -p <pass>
```
# License

© audriga GmbH.
source code is available under MIT license.

# Acknowledgement

Thanks to all members of the [IETF JMAP working group](https://datatracker.ietf.org/wg/jmap/)