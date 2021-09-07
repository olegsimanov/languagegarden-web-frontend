docker run --rm \
    --name languagegarden-backend \
    -v "${PWD}/imposters":/imposters \
    -p 2525:2525 \
    -p 8000:3000  \
    -p 8001:3001  \
    jkris/mountebank \
    --configfile /imposters/imposters.ejs \
    --allowInjection
