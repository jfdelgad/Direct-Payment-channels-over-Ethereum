const express = require('express')
var app = express();
var http = require('http').Server(app);
var io = require('socket.io')(http);
var clientsByID = {};
var clientsByAddress = {};

app.use(express.static(__dirname))
/*app.get('/', function(req, res){
  res.sendFile(__dirname + '/index.html');
});*/

io.on('connection', function(socket){
    
  socket.on('new_msg', function(msg){
    msg = JSON.parse(msg)
    if(typeof(clientsByAddress[msg.to])!="undefined"){
      var id = clientsByAddress[msg.to];
      io.sockets.connected[id].emit('new_msg', JSON.stringify(msg.tx));
    } else {
      io.sockets.connected[socket.id].emit('error1', 'err');
    }
  });

  socket.on('disconnect', function(){
    var address = clientsByID[socket.id];
    delete clientsByAddress[address]; 
    delete clientsByID[socket.id]; 
  });
  
  
  socket.on('register', function(msg){
    clientsByAddress[msg] = socket.id;
    clientsByID[socket.id] = msg;
    console.log(clientsByAddress)
  });

  socket.on('confirmTx', function(msg){
    msg = JSON.parse(msg)
    if(typeof(clientsByAddress[msg.to])!="undefined"){
      var id = clientsByAddress[msg.to];
      io.sockets.connected[id].emit('confirmTx', JSON.stringify(msg.tx));
    } else {
      io.sockets.connected[socket.id].emit('error1', 'err');;
    }
    console.log(clientsByAddress)
  });

});



http.listen(3000, function(){
  console.log('listening on *:3000');
});
