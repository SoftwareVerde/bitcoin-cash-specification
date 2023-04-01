---
hide:
  - navigation
---

# Style Guide

This page lays out the rules for contributing to the Bitcoin Cash specification.
This is not intended to be a comprehensive list of rules, please use common sense.

## General Content Guidelines

All contributions should be:

 - As accurate as possible (see below)
 - As impartial as possible
 - As impersonal as possible

They should not:

- Indicate a preference for a particular feature, configuration, or node implementation
- Call others out by name or imply your personal involvement in making the change

When referencing accuracy above, the intent is to be as true to the current state of the Bitcoin Cash protocol as possible, though this obviously has many possible interpretations.
One basic litmus test is whether a brand new implementation would need to have a certain change in order to operate without utilizing deprecated/fall-back functionality.
However, if a feature is implemented, and considered functionally complete, by the majority of active node implementations, that may also serve as a sufficient test of currency.
As such, this specification may reflect everything from the basic necessary elements of the Bitcoin Cash protocol to those that are in widespread, but not universal, use.

## Node-Specific Content Guidelines

In additional to documenting the "current" state of Bitcoin Cash, this specification also seeks to track partially implemented and experimental features, particularly where it may benefit node developers to avoid stepping on one another's toes.

When it comes to documenting these changes, there is again a range of definitions for what may be considered worth including.
Generally, the set of features that are currently developed and in the <code>master</code> (or similar) branch of a given implementations code base is probably the best place to start.
However, there may be cases where documenting changes earlier than this phase may be useful.
In general, use common sense and try to keep experimental or node-specific content minimal while still including information that may benefit others viewing this specification.

Furthermore, node-specific documentation may be best left to the developers of the implementations.
If you have a change you would like to make about node-specific functionality of an implementation you have not contributed to, at least check the master branch of that implementation's codebase.
When in doubt, reach out to a node developer to discuss the accuracy of, or best way to phrase, your contribution.
In general, content from that node implementation's developers is preferred but if they are not willing or able to, make the change yourself.

Finally, to distinguish this node-specific content from more standard, node-independent, content, please designate such content with both text and the following icon: <img src="/_static_/images/warning.png">.
This icon will serve as a simple visual indicator that the user may have ventured into territory that is experimental or otherwise not yet fully supported.

## Style and Formatting

When sensical, in order to improve git history tracking and reduce contention via merges, keep each sentence on its own line.

## Creating Pages and Links

While it is difficult to make hard-and-fast rules regarding the organization of something as complex as the Bitcoin Cash protocol, please take the time to observe the current organization of files (including URL paths and linking) before adding or moving pages.

### Pages

First, consider whether you need to create a new page or whether your content belongs in an existing page.
This probably have to be decided on a case-by-case basis but some general guidelines may help:

 - If your content is documenting a brand new process that is not directly related to any existing content, create a new page.
 - If your content is documenting a new object but where similar object already exist (e.g. a new message type) follow the convention of how other objects of that type are already documented.
If they are all already on a single page, add it there.
If they all already have their own pages, create a new page alongside the existing ones.
 - If your content is documenting a new object but no similar objects exist yet, start by making a new single page for this object in a new directory for the set of similar objects.
If you have several to add, create separate pages for each under the same new directory.
Merging many objects into a single page is a judgement call that can occur once the set is deemed to be complete and small enough for a single page.
 - If you're still not sure, use your judgement or reach out to someone who may be able to provide guidance (e.g. a node developer).

When creating pages, consider which part of the protocol the content you wish to add belongs to, and determine which directory it belongs under.

As a convention, URL components (i.e. directories and pages) should contain only lower-case letters, numbers, and hyphens.
Full words, separated by hyphens, are preferred over abbreviations, acronyms, or the use of punctuation or spaces.
For example, the page for the <code>version</code> message exists at [<code>/protocol/network/messages/version</code>](/protocol/network/messages/version).
A page relating to SLP (Simple Ledger Protocol) may exist at a path like <code>/protocol/simple-ledger-protocol/[page-name]</code>.

Once you have created the page, consider which existing pages should link to the new page and add links as appropriate.

### Links

When referencing external content (hosted on other sites/platforms), prefer the following actions, in order:

 1. Copying the content to the site (please observe content licenses for the source platforms) and linking it internally.
 2. Paraphrasing all vital content locally and then linking externally.
 3. Linking externally with sufficient context that if link breaks users have something to Google (e.g. if documenting a website itself, rather than content on it).

If you're familiar with Stack Overflow's etiquette for posting answers with links, the same logic applies here.
The primary goal is for this specification to be the only site a user needs to access to understand the entirety of the Bitcoin Cash protocol.