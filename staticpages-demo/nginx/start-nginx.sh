SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# components/build folder is referenced here directly
# because I didn't want to invest time in finding out
# how to make a link to be visible inside a container

docker run --rm \
-v "${SCRIPT_DIR}"/default.conf:/etc/nginx/conf.d/default.conf:ro \
-v "${SCRIPT_DIR}"/nginx.conf:/etc/nginx/nginx.conf:ro  \
-v "${SCRIPT_DIR}"/../../components/build/:/var/www/html/static/ \
-v "${SCRIPT_DIR}"/../player.html/:/var/www/html/player.html/ \
-v "${SCRIPT_DIR}"/../editor.html/:/var/www/html/editor.html/ \
--name languagegarden-static -p 5443:80 scr.saal.ai/nginx:1.17.1
