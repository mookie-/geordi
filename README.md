Geordi
======

Geordi is a collection of command line tools we use in our daily work with Ruby, Rails and Linux at [makandra](http://makandra.com/).

Installing the *geordi* gem will link all included tools into your `/usr/bin`:

    sudo gem install geordi

Below you can find a list of all included tools.


apache-site
-----------

Enables the given virtual host in `/etc/apache2/sites-available` and disables all other vhosts:

    site makandra-com

More information at http://makandra.com/notes/807-shell-script-to-quickly-switch-apache-sites


b
-

Runs the given command under `bundle exec` if a `Gemfile` is present in your working directory. If no `Gemfile` is present just runs the given command:

    b spec spec/models

More information at http://makandra.com/notes/684-automatically-run-bundle-exec-if-required


console-for
-----------

Opens a rails console remotely:

    console-for staging

More information at http://makandra.com/notes/1338-console-for-opens-a-rails-console-remotely-on-a-capistrano-deployment-target



cuc
-----

Runs Cucumber with the arguments you want: bundle exec, cucumber_spinner detection, separate Firefox for Selenium, etc.:

    cuc features/users.feature

More information at http://makandra.com/notes/1277-a-nicer-way-to-run-rspec-and-or-cucumber



cleanup-directory
-----------------

Removes unnecessary files from your project directory:

    cleanup-directory

More information at http://makandra.com/notes/951-shell-script-to-clean-up-a-project-directory


dump-for
--------

Dumps the database on your server for a given [Capistrano multistage](https://github.com/capistrano/capistrano/wiki/2.x-Multistage-Extension) deployment target.

    dump-for production

More information at http://makandra.com/notes/1237-script-to-create-and-copy-a-production-dump-to-your-project-root

     

dumple
------

Stores a timestamped database dump for the given Rails environment in `~/dumps`:

    dumple development

More information at http://makandra.com/notes/1008-dump-your-database-with-dumple


install-gems-remotely
---------------------

Installs all gems in your `Gemfile.lock`, as well as vendored gems, to the given host:

    install-gems-remotely my.server.com

More information at http://makandra.com/notes/692-install-a-local-gemfile-on-a-remote-server


migrate-all
---------------------

Runs `power-rake db:migrate` if parallel_tests does not exist in your `Gemfile`. Otherwise it runs the migration
in your development environment and executes `b rake parallel:prepare` after that.

    migrate-all


power-deploy
------------

Calls the Capistrano tasks `deploy`, `deploy:migrate` and `deploy:restart` on the given [Capistrano multistage](https://github.com/capistrano/capistrano/wiki/2.x-Multistage-Extension) deployment target:

    power-deploy staging

This script is considered legacy and will be removed eventually. You should [fix your deploy scripts](http://makandra.com/notes/1176-which-capistrano-hooks-to-use-for-events-to-happen-on-both-cap-deploy-and-cap-deploy-migrations) and then use [cap deploy:migrations](http://makandra.com/notes/1000-deploy-and-migrate-with-a-single-capistrano-command).


power-rake
----------

Runs the given rake task in each Rails environment in `development`, `test`, `cucumber`, `performance`, if existing:

    power-rake db:migrate

More information at http://makandra.com/notes/737-run-a-rake-task-in-all-environments


remotify-local-branch
---------------------

Pushes the given branch to the remote `origin` and tracks it:

    remotify-local-branch redesign

More information at http://makandra.com/notes/520-create-a-remote-branch-in-git


remove-executable-flags
-----------------------

Recursively removes executable flags from files in the working directory that probably shouldn't have them (like Ruby, HTML, CSS, image, Rake and similar files).

    remove-executable-flags
    
More information at http://makandra.com/notes/659-recursively-remove-unnecessary-execute-flags


rs
-----

Runs RSpec with the arguments you want: RSpec 1/2 detection, bundle exec, rspec_spinner detection, etc.:

    rs spec/models/user_spec.rb

More information at http://makandra.com/notes/1277-a-nicer-way-to-run-rspec-and-or-cucumber


setup-firefox-for-selenium
--------------------------

Helps you create an frozen version of Firefox, so your Selenium tests will no longer break whenever Firefox updates:

    setup-firefox-for-selenium

More information at http://makandra.com/notes/1575-how-to-install-an-frozen-version-of-firefox-for-your-selenium-tests


shell-for
---------

Opens an SSH shell on the given [Capistrano multistage](https://github.com/capistrano/capistrano/wiki/2.x-Multistage-Extension) deployment target:

    shell-for production

Now it can also be called with any command to be remotely executed before loading the bash. `--no-bash` skips the bash.

    shell-for staging --no-bash top

More information at http://makandra.com/notes/1209-script-to-open-an-ssh-shell-to-a-capistrano-deployment-target   


tests
--------------

Runs both `rs` and `cuc`. Call from any project directory:

    tests

More information at http://makandra.com/notes/1277-a-nicer-way-to-run-rspec-and-or-cucumber
