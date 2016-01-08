var jwt = require('jsonwebtoken');

exports.handler = function(event, context) {
  var token = jwt.sign(event, 'shhhhh');
  context.succeed(token);
};

