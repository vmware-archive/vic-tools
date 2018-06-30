# Contributing to vic-tools

The vic-tools project team welcomes contributions from the community. If you
wish to contribute code and you have not signed our contributor license
agreement (CLA), our bot will update the issue when you open a Pull Request.
For any questions about the CLA process, please refer to our
[FAQ][cla].

[cla]:https://cla.vmware.com/faq


## Community

To connect with the community, please [join][slack] our public Slack workspace.

[slack]:https://code.vmware.com/join


## Getting started

To begin contributing, please create your own [fork][fork] of this repository.
This will allow you to share proposed changes with the community for review.

The [hub][hub] utility can be used to do this from the command line.

Example:

``` shell
hub clone vmware/vic-tools
hub fork
```

[fork]:https://help.github.com/articles/fork-a-repo/
[hub]:https://hub.github.com/

## Contribution flow

A rough outline of a contributor's workflow might look like:

1. Create a topic branch from where you want to base your work
2. Make commits of logical units
3. Make sure your commit messages are in the proper format (see below)
4. Push your changes to a topic branch in your fork of the repository
5. Submit a pull request

### Staying in sync with upstream

When your branch gets out of sync with the vmware/master branch, use the
following to update:

``` shell
git checkout my-new-feature
git remote update
git pull --rebase origin master
git push --force-with-lease my-new-feature
```

Note: In this case, we are able to invoke `git push` without specifying a remote
because we previously invoked `git push` with the `-u` (`--set-upstream` flag).

To make `--rebase` the default behavior when invoking `git pull`, you can use
`git config pull.rebase true`. This makes the history of your topic branch
easier to read by avoiding merge commits.

### Formatting commit messages

While the contents of your changes are easily improved in the future, your
commit message becomes part the permanent historical record for the repository.
Please take the time to craft meaningful commits with useful messages.

[How to Write a Git Commit Message][commitmsg] provides helpful conventions.

To be reminded when you may be making a common commit message mistake, you can
use the [git-good-commit][commithook] commit hook.

Example:
```shell
curl https://cdn.rawgit.com/tommarshall/git-good-commit/v0.6.1/hook.sh > .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg
```

Please include any related GitHub issue references in the body of the pull
request, but not the commit message. See [GFM syntax][gfmsyntax] for referencing
issues and commits.

[commitmsg]:http://chris.beams.io/posts/git-commit/
[commithook]:https://github.com/tommarshall/git-good-commit
[gfmsyntax]:https://guides.github.com/features/mastering-markdown/#GitHub-flavored-markdown

### Updating pull requests

If your PR fails to pass CI or needs changes based on code review, you'll want
to make additional commits to address these and push them to your topic branch
on your fork.

Providing updates this way instead of amending your existing commit makes it
easier for reviewers to see what has changed since they last looked at your
pull request.

You can use the `--fixup` and `--squash` options of `git commit` to communicate
your intent to combine these changes with a previous commit before merging.

Be sure to add a comment to the PR indicating your new changes are ready to
review, as GitHub does not generate a notification when you push to your topic
branch to update your pull request.

### Preparing to merge

After the review process is complete and you are ready to merge your changes,
you should rebase your changes into a series of meaningful, atomic commits.

If you have used the `--fixup` and `--squash` options suggested above, you can
leverage `git rebase -i --autosquash` to re-organize some of your history
automatically based on the intent you previously communicated.

If you have multiple commits on your topic branch, update the first line of
each commit's message to include your PR number. If you have a single commit,
you can use the "Squash & Merge" operation to do this automatically.

Once you've cleaned up the history on your topic branch, it's best practice to
wait for CI to run one last time before merging.

### Merging

Generally, we avoid merge commits on `master`. We suggest using "Squash & Merge"
if you are merging a single commit or "Rebase & Merge" if you are merging a
series of related commits. If you believe creating a merge commit is the right
operation for your change (e.g., because you're merging a long-lived feature
branch), please note that in your pull request.


## Reporting bugs and creating issues

Communicating clearly helps with efficient triage and resolution of reported
issues.

The summary of each issue will likely be read by many people. Quickly conveying
the essence of the problem you are experiencing helps get the right people
involved. Reports which are vague or unclear may take longer to be routed to
a domain expert.

The body of an issue should communicate what you are trying to accomplish and
why; understanding your goal allows others to suggest potential workarounds. It
should include specific details about what is (or isn't happening).

Proactively including screenshots and logs can be very helpful. When including
logs, please ensure that formatting is preserved by using [code blocks][code].
Consider formatting longer logs so that they are not shown by default.

Example:
```
<detail><summary>View Logs</summary>
<pre><code>
... (log content)
</code></pre>
</detail>
```

[code]:https://help.github.com/articles/creating-and-highlighting-code-blocks/

