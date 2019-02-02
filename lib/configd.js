const Promise = require('bluebird');
const _ = require('lodash');
const path = require('path');
const fs = require('fs');
Promise.promisifyAll(fs);
const globAsync = Promise.promisify(require('glob'));
const readers = require('./readers');
const parsers = require('./parsers');
const _readers = [];
const _parsers = [];

const _readFile = function(filename) {
  let _reader = readers.local;
  let _parser = null;
  configd.readers.some(function(reader) {
    if (filename.match(reader.pattern)) {
      _reader = reader.handler;
      return true;
    }
  });
  configd.parsers.some(function(parser) {
    if (filename.match(parser.pattern)) {
      _parser = parser.handler;
      return true;
    }
  });
  return _reader(filename).then(function(data) {
    if (toString.call(data) !== '[object String]') {
      return data;
    }
    if (toString.call(_parser) !== '[object Function]') {
      throw new Error("Can not find parser for " + filename);
    }
    data = _parser(data, {
      filename: filename
    });
    if (!data) {
      throw new Error("Content is empty! " + filename);
    }
    return data;
  });
};

const _autoloadPlugins = function(configd) {
  if (configd._autoloaded) {
    return Promise.resolve();
  }
  return Promise.reduce(module.paths, function(plugins, dirname) {
    return globAsync(dirname + "/configd-*").then(function(_plugins) {
      return plugins.concat(_plugins);
    });
  }, []).then(function(plugins) {
    return plugins.forEach(function(pluginPath) {
      const basename = path.basename(pluginPath);
      if (!configd._plugins[basename]) {
        try {
          const plugin = require(pluginPath);
          plugin(configd);
          return configd._plugins[basename] = plugin;
        } catch (error) {
          const err = error;
          return console.warn("Load plugin " + pluginPath + " error: " + err.message);
        }
      }
    });
  }).then(function() {
    return configd._autoloaded = true;
  });
};


/**
 * Start define primary configd process
 * @param  {Array} sources - An array of sources
 * @param  {Object} options - Other options
 * @return {Promise} configs - Merged configs
 */

const configd = function(sources, options) {
  return _autoloadPlugins(configd).then(function() {
    return Promise.reduce(sources, function(mergedConfig, sourceName) {
      return _readFile(sourceName).then(function(data) {
        return _.merge(mergedConfig, data);
      });
    }, {});
  });
};

configd._autoloaded = false;

configd._plugins = {};

configd.route = configd.reader = function(pattern, fn) {
  return _readers.push({
    pattern: pattern,
    handler: fn
  });
};

configd.parser = function(pattern, fn) {
  return _parsers.push({
    pattern: pattern,
    handler: fn
  });
};

Object.defineProperty(configd, 'readers', {
  get: function() {
    return _readers;
  }
});

Object.defineProperty(configd, 'parsers', {
  get: function() {
    return _parsers;
  }
});

configd.reader(/^http(s)?:\/\//, readers.http);
configd.reader(/^ssh\:\/\//, readers.ssh);
configd.reader(/^git\:\/\//, readers.git);
configd.parser(/\.json$/i, parsers.json);
configd.parser(/\.js$/i, parsers.js);
configd.parser(/\.coffee$/i, parsers.coffee);

module.exports = configd;