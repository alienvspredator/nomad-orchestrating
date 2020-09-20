# Lab 3

This is a Vagrant's pre-configured VM with a completed exercise for the third lab.
This example shows how to orchestrate containers using [nomad](https://www.nomadproject.io/).

## Start-up instructions

1. To create a VM, simply run the `vagrant up` command from the root directory of the repository.
2. Connect via ssh using the command `vagrant ssh`.
3. Navigate to the data directory with the following command: `cd /vagrant/lab3`.
4. Modify `lab3/tgbot.nomad` (in the repository root directory) and provide your telegram token (replace `YOUR_TELEGRAM_TOKEN`) in the `group -> task -> env` block.

    Where `YOUR_TELEGRAM_TOKEN_HERE` is a your telegram bot token. If you don't have one, create a new bot with [BotFather](https://t.me/BotFather). The token can also be stored in the google secrets manager (See the [bot](https://github.com/alienvspredator/simple-tgbot) main repostory for details).

5. Start the `cockroachdb` job: `nomad run cockroachdb.nomad`. This is a DBMS instance.
6. Run the database migrations: `docker run --net=host --env-file .env -e DB_HOST=localhost danyloshevchenko123/tgbot-migrate:v1.0.0`
7. Start the `tgbot` job: `nomad run tgbot.nomad`.
8. Chatting.
