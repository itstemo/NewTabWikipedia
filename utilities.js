(function() {
  function updateClock() {
    var currentTime = new Date();
    var hours = currentTime.getHours();
    var minutes = currentTime.getMinutes();
    var seconds = currentTime.getSeconds();
    if (minutes < 10){
      minutes = "0" + minutes;
    }
    if (seconds < 10){
      seconds = "0" + seconds;
    }
    var v = hours + ":" + minutes + ":" + seconds + " ";
    if(hours > 11){
      v+="PM";
    } else {
      v+="AM"
    }
    setTimeout("updateTime()",1000);
    document.getElementById('time').innerHTML = v;
  }

  updateClock();
})();
