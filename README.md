Languagegarden
====

Setup project
----
1. Ensure that you have Homebrew (https://brew.sh) installed.
2. Ensure that you have Homebrew Bundle installed (if you enter `brew bundle` it should auto-install itself).
3. Ensure that you can setup easily virtualenv with Python 2.
   My recommended way to use pyenv + virtualenvwrapper:

        brew install pyenv
        brew install virtualenvwrapper
        pyenv install 2.7.18

4. Setup virtualenv (again, using pyenv + virtualenvwrapper):

        mkvirtualenv -p $HOME/.pyenv/versions/2.7.18/bin/python2.7 lg

    (virtualenv should be activated automatically)


5. Execute install script (with the patch it should now work on Mac OS):

        ./scripts/setup/install.sh

Build project
----

    cd components/
    webpack
    cd ..

Running editor (for development)
----

4. This is optional, but required if you want to develop the
   languagegarden editor and player, which is placed in separate
   `components` directory. After virtualenv activiation, run the development:

        cd components/
        webpack --cw --progress

   The `grunt serve` does this once during startup, but does not watch
   for changes in the `components` directory (for performance reasons).
   Therefore you need to run separate command.


Now, you should be able to access the Languagegarden locally here:
[http://localhost:9000/](http://localhost:9000/)
