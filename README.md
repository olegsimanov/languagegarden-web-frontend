Languagegarden
====

here are the instructions for Mac OS
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

6. Build initial version of components

        cd components/
        webpack
        cd ..

7. Setup local SQLite DB:

        cd backend
        ../scripts/development/reload_db_with_test_data.sh
        cd ..

8. (Optional) Change the admin password to 'admin' (I forgot what was the default one) with this one-liner:

        cd backend
        python -c 'import os;os.environ.setdefault("DJANGO_SETTINGS_MODULE", "languagegarden.settings.localhost");import django;django.setup();from languagegarden.accounts.models import User;u = User.objects.get(username="admin");u.set_password("admin");u.save()'
        cd ..

Running project (for development)
----

1. Run in 2 separate terminals with virtualenv enabled. If you're using virtualenvwrapper, you can just type

        workon lg

2. After virtualenv activiation, run the development frontend server:

        cd frontend/
        grunt serve

3. After virtualenv activiation, run the development backend server:

        cd backend/
        ./manage.py runserver

   This server will automatically redirect the calls to /api /admin,
   /static etc. to the backend server.
   You can change the backend host and port via custom `GruntConfig.coffee`
   config file. This can be extremely useful if you're frontend developer
   and not using Ubuntu. In this case you could setup the project on VM,
   setup the frontend part on your host machine and access the backend
   via external host/port.

Now, you should be able to access the lessons admin via: http://localhost:9000/admin/lessons/lesson/
You can click on "Add lesson" to add a new one.

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

(The default credentials for the admin can be found
[here](https://wiki.10clouds.com/display/LAN/Credentials))


If you're annoyed by running these 3 commands in separate shell each time,
I would recommend to use **tmuxinator** tool which can automate the startup.


Before you start to write any code
----

1. Install [editorconfig](http://editorconfig.org/) plugin into your editor.
   Or at least follow the rules described in the `.editorconfig` file.

2. Install various linters (pyflake8 for python,
   jshint if you want to write code in JS) into your editor. Yes, we also try
   to follow the max-79-chars-per-line rule!

3. Check out the [technical documentation](https://wiki.10clouds.com/display/LAN/Technical+Documentation)
   on our wiki. This can be extremely useful if you're developing the
   `components` part.

4. If you're a frontend developer and you want to know more about the
   backend REST API without digging into Python code, you can use the swagger
   to play around. It should be available here:

   [http://localhost:9000/api-docs/](http://localhost:9000/api-docs/)
