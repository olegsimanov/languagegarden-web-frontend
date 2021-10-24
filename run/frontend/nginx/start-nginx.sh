SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# components/build folder is referenced here directly
# because I didn't want to invest time in finding out
# how to make a link to be visible inside a container

docker run --rm \
-v "${SCRIPT_DIR}"/default.conf:/etc/nginx/conf.d/default.conf:ro \
-v "${SCRIPT_DIR}"/nginx.conf:/etc/nginx/nginx.conf:ro  \
-v "${SCRIPT_DIR}"/../../../components/build/:/var/www/html/static/ \
-v "${SCRIPT_DIR}"/../editor.html/:/var/www/html/editor.html/ \
--name languagegarden-frontend-modified -p 5442:80 scr.saal.ai/nginx:1.17.1
