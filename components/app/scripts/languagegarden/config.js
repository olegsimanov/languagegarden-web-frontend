// TODO: Convert to ES2016/ESM syntax
var config = {
  apiBaseUrl: '/api/v2/',
}

function setValue(name, value) {
  config[name] = value;
}

function getValue(name) {
  return config[name];
}

function configure(options = {}) {
  var prop;
  for (prop in options) {
    if (options.hasOwnProperty(prop)) {
      setValue(prop, options[prop]);
    }
  }
}

function getUrlRoot(apiResourceName) {
  var apiBaseUrl = getValue('apiBaseUrl');
  return apiBaseUrl + apiResourceName + '/';
}

module.exports = {
  getValue: getValue,
  setValue: setValue,
  configure: configure,
  getUrlRoot: getUrlRoot,
}
