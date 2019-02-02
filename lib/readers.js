
const fs = require('fs');
const path = require('path');
const os = require('os');
const Promise = require('bluebird');
const request = require('request');
const exec = require('child_process').exec;
const requestAsync = Promise.promisify(request);
module.exports = {

  /**
   * Default reader, read local files
   */
  local: function(source) {
    return fs.readFileAsync(source, {
      encoding: 'UTF-8'
    });
  },

  /**
   * Read remote file through ssh
   */
  ssh: function(source) {
    source = source.slice(6);
    const ref = source.split(':')
    const server = ref[0]
    const filename = ref[1];
    return new Promise(function(resolve, reject) {
      const child = exec("ssh " + server + " \"cat " + filename + "\"");
      const data = "";
      child.stdout.on('data', function(_data) {
        return data += _data;
      });
      child.stderr.pipe(process.stderr);
      return child.on('exit', function(code) {
        if (code !== 0) {
          return reject(new Error("The upload process exit with a non-zero value!"));
        }
        return resolve(data);
      });
    });
  },

  /**
   * Read file from git
   */
  git: function(source) {
    var i, origin, ref1, version;
    source = source.slice(6);
    const ref = source.split(':')
    const origins = 2 <= ref.length ? ref.slice(0, i = ref.length - 1) : (i = 0, []), filename = ref[i++];
    origin = origins.join(':');
    ref1 = origin.split('#'), origin = ref1[0], version = ref1[1];
    const local = path.join(os.tmpdir(), 'configd', path.basename(origin));
    version || (version = 'master');
    return new Promise(function(resolve, reject) {
      return fs.exists(local, function(exists) {
        return resolve(exists);
      });
    }).then(function(exists) {
      var cmd;
      if (exists) {
        cmd = "cd " + local + " && git fetch --all && git reset --hard origin/" + version;
      } else {
        cmd = "git clone " + origin + " " + local;
      }
      return new Promise(function(resolve, reject) {
        var child;
        child = exec(cmd);
        child.stdout.pipe(process.stdout);
        child.stderr.pipe(process.stderr);
        return child.on('exit', function(code) {
          if (code !== 0) {
            return reject(new Error("The upload process exit with a non-zero value!"));
          }
          return resolve();
        });
      });
    }).then(function() {
      return fs.readFileAsync(path.join(local, filename), {
        encoding: 'UTF-8'
      });
    });
  },

  /**
   * Read file from http service
   */
  http: function(source) {
    return requestAsync({
      url: source,
      method: 'GET',
      headers: {
        "User-Agent": "configd spider"
      }
    }).then(function(res) {
      var body, ref;
      if (!(res.statusCode >= 200 && res.statusCode < 300)) {
        throw new Error("bad request " + res.statusCode + " at " + source);
      }
      if (((ref = res.headers['content-type']) != null ? ref.indexOf('application/json') : void 0) > -1) {
        body = JSON.parse(res.body);
      }
      return body;
    });
  }
};