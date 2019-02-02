const path = require('path');
const commander = require('commander');
const chalk = require('chalk');
const Promise = require('bluebird');
const fs = require('fs');
Promise.promisifyAll(fs);
const mkdirpAsync = Promise.promisify(require('mkdirp'));
const configd = require('./configd');
const pkg = require('../package.json');

_writeFile = function(filename, data) {
  const dir = path.dirname(filename);
  return new Promise(function(resolve, reject) {
    return fs.exists(dir, function(exists) {
      return resolve(exists);
    });
  }).then(function(exists) {
    if (exists) {
      return;
    }
    return mkdirpAsync(dir);
  }).then(function() {
    return fs.writeFileAsync(filename, data);
  });
};

module.exports = function() {
  return commander
  .version(pkg.version)
  .usage("source1 source2 protocol://source3 ... destination")
  .action(function(... args) {
    if (!(args.length > 2)) {
      console.warn(chalk.yellow("  At least one source and one destination need to be provided!"));
      return process.exit(1);
    }
    const sources = args.slice(0, -2);
    const destination = args[args.length - 2];
    const options = args[args.length - 1];
    return configd(sources, destination, options).then(function(merged) {
      return _writeFile(destination, JSON.stringify(merged, null, 2));
    }).then(function(merged) {
      console.log(chalk.green("  Source " + sources + " have merged into " + destination));
      return process.exit(0);
    }).catch(function(err) {
      console.error(chalk.red("  " + err.message));
      return process.exit(2);
    });
  }).parse(process.argv);
};
