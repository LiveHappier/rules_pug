const pug = require("pug");
const fs = require("fs");

const params = process.argv.slice(2);
const src = params[0];
const outFile = params[1];

// Compile the source code
const compiledFunction = pug.compileFile(src);
const data = compiledFunction();
const buffer = Buffer.from(data);

fs.open(outFile, "w", function(err, fd) {
  if (err) {
    throw "error opening file: " + err;
  }

  fs.write(fd, buffer, 0, buffer.length, null, function(err) {
    if (err) throw "error writing file: " + err;
    fs.close(fd, function(){});
  });
});
