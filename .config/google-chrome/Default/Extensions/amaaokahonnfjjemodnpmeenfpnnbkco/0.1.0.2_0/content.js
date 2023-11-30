//this page load a half second before //tab.status is complete
//  var d=new Date(); console.log("page loaded"); console.log(d.getTime());
//  chrome.runtime.sendMessage({action: "get_answers"}, function(response) {
//  var co=new commando();
//  var d=new Date(); console.log("loading answers"); console.log(d.getTime());
//        console.log(response);
//        co.loadAnswers(response);
//  });

//  setTimeout(function(){

//  var d=new Date(); console.log("testing later send start"); console.log(d.getTime());
//  chrome.runtime.sendMessage({action: "get_answers"}, function(response) {
//  var d=new Date(); console.log("testing later send end"); console.log(d.getTime());

//  });

//  }, 3000);


//  chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
//    // listen for messages sent from background.js
//  //  console.log(request);
//      if (request.message === 'answers_loaded') {
//           // alert(request.url);
//            var co=new commando();
//                co.loadAnswers(request);
//      }
//  });

function commando() {

  //this.endpoint="https://staging.codegrepper.com/api";
  //this.web_endpoint="https://staging.codegrepper.com";
  this.endpoint="https://www.grepper.com/api";
  this.web_endpoint="https://www.grepper.com";

  this.listenForFeedbackOnAnswer = true; 
  this.search = getParameterByName("q");
  this.tifgrpr = (getParameterByName("tifgrpr")) ? "&tifgrpr=1" : "";//this is from grpr
  this.do_show_grepper_comments = (getParameterByName("dsgcf")) ? getParameterByName("dsgcf") : false;//this is from dsgcf
  this.user_id=false;
  this.answers=[];
  this.products=[];
  this.writeups=[];
  //this.doneLoadingAnswersDom=false;
  this.languageGuess="whatever";
  this.isWrittingAnswer=false;
  this.copyClickedTimes=0;
  this.bounty=0;
  this.needsResults1ToDisplayOnDomLoaded=false;
  var currentDate = new Date();
  this.currentTime = currentDate.getTime();
  this.resultsURLS=[];
  this.loadedCodeMirrorModes=[];
  this.moreAnswers=[];
  this.moreResultsInitiated=false;
  this.moreAnswersTotalCount=0;
  this.disableKeyTriggers=false;
   //if this get past 15 we have been running for 150 millo seconds and dom has not loaded, something is wrong so finish
  this.stateDomLoadedNoResults=0;
  this.mHasBeenClicked=false;
  this.oHasBeenClicked=false;
  this.stream;
  this.recorder;
  this.videoHolder = false;
  this.uploadedVideoName = false;
  this.currentEditingAnswer=false;
  this.grepperSpecialKeysDown={};
  this.grepperActionDownPressedKey=false;
  this.grepcc_tips_left=0;
  this.showWrongAnswerFeedbackButton=false;
  this.user_data=false;
  this.f_more_results=0;
  this.advanced_answer_default=0;
  this.gae =false;
  this.simpleAnswerBoxHolder=false;
  this.searchEngineId=1;//1 is google, 2 is you.com
  this.grepperDomElements=[];
}

//commando.prototype.loadAnswers=function(request){
//      this.search=request.search;
//      this.answers=request.answers;
//      this.user_id="efa1a5314f0e863dd7615224573953eeb512b6a97481b330a38d74d2731e";
//      this.displayResults();
//}

commando.prototype.loadResultsWhenReadyYouCom =function(){
 this.statsDomInterval = setInterval(function(){
    if(this.getStatsDomYouCom()){
        clearInterval(this.statsDomInterval);
        this.displayResults();
    }
 }.bind(this), 10);

  setTimeout(function(){
        clearInterval(this.statsDomInterval);
  }.bind(this), 3000);
}

commando.prototype.removeGrepperResultsFromYouCom=function(){
    this.grepperDomElements.forEach((element) => {
        if (element && element.parentNode) {
            element.parentNode.removeChild(element);
        }
    });

    this.grepperDomElements=[];
    this.grepperDomElements.length = 0;
}
commando.prototype.runYouComSearch=function(){
    this.search = getParameterByName("q");
 // var tbm = getParameterByName("tbm");
 // if(tbm){
 //     return false;
 // }
    this.getUserId().then(function(){
          this.getAnswers().then(function(){
            this.statsDom=false;
            this.loadResultsWhenReadyYouCom();
          }.bind(this));
     }.bind(this))

    //push onto history
  //this.settupKeyBindings();
   chrome.runtime.sendMessage({
      "action":"resultSearchAction",
      "search":this.search,
      "search_time": this.currentTime,
      "fallback":1,
      "results":[]
    }); 
}

commando.prototype.init=function(){
  
    this.searchEngineId=1;
    if(window.location.pathname !="/search"){
        return;
    }
    
    //get the user id
    this.getUserId().then(function(){
        this.listenForStatDomLoaded();
      //var d=new Date(); console.log("user id got"); console.log(d.getTime());
        this.getAnswers().then(function(){
          if(this.answers.length > 0){
              //this.getAndDisplayVotes();
          }
        }.bind(this));
        //after we get user id lets check on messaging

    }.bind(this));

    //push onto history
  this.settupKeyBindings();

   chrome.runtime.sendMessage({
      "action":"resultSearchAction",
      "search":this.search,
      "search_time": this.currentTime,
      "fallback":1,
      "results":[]
    }); 
}

//  commando.prototype.setupCopyListener=function(){

//     this.copyClickedTimes=0;
//     window.grepperControlDown=false;

//     document.addEventListener('keydown', function(event) {
//          if(event.key ==="Meta" || event.key==="Control"){
//             window.grepperControlDown=true;
//          }
//     });
//   document.addEventListener('keyup', function(event) {
//        if(event.key ==="Meta" || event.key==="Control"){
//          //they were pry trying to copy regulatlry
//          setTimeout(function(){
//               window.grepperControlDown=false;
//          }, 500);
//        }
//   });
//     
//     document.addEventListener('keyup', function(event) {
//         //hmm, what to do with this??? 
//          var tag = document.activeElement.tagName;
//          if(tag==="INPUT" || tag === "TEXTAREA"){
//              return;    
//          }    

//          if(event.key=="c"){
//              if(window.grepperControlDown){
//                  return;
//              }

//              if(this.copyClickedTimes >= this.answers.length){
//                  this.copyClickedTimes=0;    
//              }

//              this.selectCode(this.answers[this.copyClickedTimes].codeResults);
//              this.copyClickedTimes++;
//              event.stopPropagation();
//              return;
//          }
//      }.bind(this));

//  }

commando.prototype.selectCode=function(e){
	// Source: http://stackoverflow.com/a/11128179/2757940
		if (document.body.createTextRange) { // ms
			var range = document.body.createTextRange();
			range.moveToElementText(e);
			range.select();
		} else if (window.getSelection) { // moz, opera, webkit
			var selection = window.getSelection();
			var range = document.createRange();
			range.selectNodeContents(e);
			selection.removeAllRanges();
			selection.addRange(range);
		}
      document.execCommand("copy");
}
commando.prototype.settupKeyBindings=function(){

    document.addEventListener('keydown', function(event) {
        if(!this.statsDom){ return; }

        if(event.key ==="Meta" || event.key==="Control" || event.key==="Shift" || event.key==="Alt"){
           this.grepperSpecialKeysDown[event.key]= true;
          //setTimeout(function(){
          //    this.grepperSpecialKeysDown[event.key]= true;
          //}.bind(this), 390);
           return;
        }

        if(event.repeat){
            return
        }

        if(Object.keys(this.grepperSpecialKeysDown).length){
            return;
        }

        //key is primed and has been press down without Meta being pressed
        //what are we preventing with all of this
        //1.user goes to hit Ctrl+c and hits c first then Ctrl... still a no go 
        //2. User Hits ctrl+c, pulls up off Ctrl and holds c too long...still a no go
        //this has to be set and only can be set if 
        if(event.key=="a"||event.key=="m"||event.key=="o"||event.key=="c"){
            this.grepperActionDownPressedKey=event.key;

        }

    }.bind(this));

    document.addEventListener('keyup', function(event) {
        if(!this.statsDom){ return; }

        if(event.key ==="Meta" || event.key==="Control" || event.key==="Shift" || event.key==="Alt"){
            //we need refractory period
            //I remove refractory period bc consequnces to mistyping at really low just 
            //a time out would help spot where they hit ctrl up and down then hit c
            //setTimeout(function(){
               delete this.grepperSpecialKeysDown[event.key];
            //}.bind(this), 400);

        }else if(Object.keys(this.grepperSpecialKeysDown).length){
            //return;

        }else if(!this.grepperActionDownPressedKey){
            //return;

        }else if (this.disableKeyTriggers){

        }else if (this.isActiveElementEditable()){

        }else if(this.searchEngineId !=2 && event.key=="a" && this.grepperActionDownPressedKey =="a"){
            this.displayAnswerBoxDefault();
            event.stopPropagation();
            //return;
       }else if(this.searchEngineId !=2 && event.key=="m" && this.grepperActionDownPressedKey =="m"){
            if(this.mHasBeenClicked){ return; }
            this.mHasBeenClicked=true;
            this.loadMyMoreResults(0);
            event.stopPropagation();
            //return;
       }else if(this.searchEngineId !=2 && event.key=="o" && this.grepperActionDownPressedKey =="o"){
            if(this.oHasBeenClicked){ return; }
            this.oHasBeenClicked=true;
            this.loadMyMoreResults(1);
            event.stopPropagation();
            //return;
     //}else if(event.key=="w" && this.grepperActionDownPressedKey =="w"){
     //   this.addNewWriteup(); 
     //   event.stopPropagation();
     //   //return;
       }else if(event.key=="c" && this.grepperActionDownPressedKey =="c"){
           if(this.answers.length > 0){

            //todo make this better to loop through all advacned code snippet results
              if(this.copyClickedTimes >= this.answers.length){
                  this.copyClickedTimes=0;    
              }

              if(this.answers[this.copyClickedTimes].codeResults.length){
                this.selectCode(this.answers[this.copyClickedTimes].codeResults[0]);
              }

              this.copyClickedTimes++;
              event.stopPropagation();
            //  return;
            }
      }

      //so this always needs to be reset 
      this.grepperActionDownPressedKey=false;

    }.bind(this));
}

commando.prototype.isActiveElementEditable=function(){
  

       var tag = false;

       if(document.activeElement){
             tag = document.activeElement.tagName;
       }else{
           return false;//not active element
       }

       //need to detect content editable too
       if(tag==="INPUT" || tag === "TEXTAREA" || tag==="SELECT" || tag.value){
            return true;    
       }

       return false;
}

//  commando.prototype.getUserId=function(){
//      return new Promise(function (resolve, reject) {
//          chrome.extension.sendMessage({"action":"getUser"}, function(response) {
//              this.user_id=response.user.email;
//              resolve();
//          }.bind(this));
//      }.bind(this));
//  }


//here we try and use localStorage, if we dont
//have it then we use chrome.storage.sync
//so this resolves twice, first wins - it will always reset the local storage
commando.prototype.getUserId=function(){

  return new Promise(function (resolve, reject) {
    this.user_id=localStorage.getItem("grepper_user_id");
    this.access_token=localStorage.getItem("grepper_access_token");
    if(this.user_id && this.user_id > 0){
        resolve();
        //return;//So wa want to alwas reset the local storage for nex time
    }

    chrome.storage.sync.get(['grepper_user_id','access_token'], function(items) {
        this.user_id = items.grepper_user_id;
        localStorage.setItem("grepper_user_id",this.user_id);
        if(items.access_token){
            this.access_token=items.access_token;
            localStorage.setItem("grepper_access_token",items.access_token);
        }else{
            localStorage.setItem("grepper_access_token","");
        }
        resolve();
    }.bind(this));

  }.bind(this));
}



//consider using muttations oberver
commando.prototype.listenForStatDomLoaded=function(){

//this is just for search div to be loaed
 this.statsDomInterval = setInterval(function(){
    if(this.getStatsDom()){
        clearInterval(this.statsDomInterval);
        if(this.needsResults1ToDisplayOnDomLoaded){
            this.displayResults();
            //this.displayResultEnhanced();
            this.displayProducts();
        }
    }
 }.bind(this), 10);

//this is just for all results to be loaded 
 this.statsDomResultsLoadedInterval = setInterval(function(){
    if(this.getStatsDomAfterAllResults()){
        clearInterval(this.statsDomResultsLoadedInterval);
        this.getAnswers2();
        this.setUpResultsClickListeners();//we still need this
    }
 }.bind(this), 100);


  //don't poll for more than 3 seconds
  setTimeout(function(){
        clearInterval(this.statsDomResultsLoadedInterval);
        clearInterval(this.statsDomInterval);
  }.bind(this), 3000);

}


commando.prototype.getAnswers=function(){
  return new Promise(function (resolve, reject) {
    makeRequest('GET', this.endpoint+"/get_answers_1.php?v=4&s="+encodeURIComponent(this.search)+"&u="+this.user_id+this.tifgrpr,{},true).then(function(data){
    
        var results=JSON.parse(data);
        this.answers=results.answers;
        this.products=results.products;
       if(results.hasOwnProperty('f_more_results')){
            this.f_more_results=parseInt(results.f_more_results);
        }
        if(results.hasOwnProperty('grepcc_tips_left')){
            this.grepcc_tips_left=results.grepcc_tips_left;
        }
        if(results.hasOwnProperty('allow_wrong_answers_feedback')){
            this.showWrongAnswerFeedbackButton=results.allow_wrong_answers_feedback;
        }

        if(results.hasOwnProperty('writeups')){
            this.writeups=results.writeups;
        }
        if(results.hasOwnProperty("advanced_answer_default")){
            //this.advanced_answer_default=results.advanced_answer_default;
        }

        this.moreAnswers= results.more_answers;
        if(this.getStatsDom()){
            this.displayResults();
            this.displayProducts();
        }else{
            this.needsResults1ToDisplayOnDomLoaded=true;
        }
        resolve();
    }.bind(this));
  }.bind(this));
};

/*
commando.prototype.listenForStatDomAnswersLoaded=function(data){
 this.doneLoadingAnswersDomInterval = setInterval(function(){
    if(this.doneLoadingAnswersDom){
        clearInterval(this.doneLoadingAnswersDomInterval);
        //this.displayVotes(data);
    }
 }.bind(this,data), 10);

  setTimeout(function(){
        clearInterval(this.doneLoadingAnswersDomInterval);
  }, 9000);
}
*/


/*
commando.prototype.setupFeedBackListenersForExtra=function () {
    if(!this.answers.length){ return; }

    //setup copy events on answers
    for(let i=0;i<this.answers.length;i++){
          this.answers[i].codeResults.addEventListener("copy", function(){
            makeRequest('POST', this.endpoint+"/feedback.php?vote=2&search_answer_result_id="+this.answers[i].search_answer_result_id+"&u="+this.user_id).then(function(data){});
          }.bind(this));
    }
}
*/

commando.prototype.setupFeedBackListeners=function () {
    if(!this.answers.length){ return; }

    //hook into on handleResultClick
    this.listenForFeedbackOnAnswer = true; 
    //setup copy events on answers
    for(let i=0;i<this.answers.length;i++){
        let listenerElement=this.answers[i].myDom;
        if(!this.answers[i].is_advanced){
            listenerElement=this.answers[i].codeResults[0];
        }

              listenerElement.addEventListener("copy", function(){
                 var message = {
                        "action":"sendFeedback",
                        "user_id" :this.user_id,
                        "access_token" :this.access_token,
                        "search_answer_result_id":this.answers[i].search_answer_result_id,
                        "vote":2
                 };
                chrome.runtime.sendMessage(message);
              }.bind(this));

              let enterX,leaveX,enterY,leaveY,readTimeTotal,readTimeStart,readTimeEnd;
              let tClicks=0;

              listenerElement.addEventListener("click", function(e){
                    tClicks+=1;
              }.bind(this));

              listenerElement.addEventListener("mouseenter", function(e){
                    enterX=e.offsetX;
                    enterY=e.offsetY;
                    readTimeStart = new Date().getTime();
              }.bind(this));

              listenerElement.addEventListener("mouseleave", function(e){
                    leaveX=e.offsetX;
                    leaveY=e.offsetY;
                    readTimeEnd = new Date().getTime();
                     var message = {
                            "action":"sendFeedback",
                            "user_id" :this.user_id,
                            "access_token" :this.access_token,
                            "search_answer_result_id":this.answers[i].search_answer_result_id,
                            "sx":enterX,
                            "sy":enterY,
                            "lx":leaveX,
                            "ly":leaveY,
                            "tc":tClicks,
                            "ht":(readTimeEnd-readTimeStart),
                            "vote":8
                     };
                    if((readTimeEnd - readTimeStart) > 1000 ){
                     chrome.runtime.sendMessage(message);
                    }

              }.bind(this));
    }
}

/*
commando.prototype.getAndDisplayVotes=function () {
var answer_ids="";
for(var i=0;i<this.answers.length;i++){
    answer_ids+=this.answers[i].id+",";
}
    answer_ids=answer_ids.substring(0, answer_ids.length - 1);

 makeRequest('GET', this.endpoint+"/vote.php?answer_ids="+answer_ids+"&u="+this.user_id+"&term="+this.search).then(function(data){
        //here we need to wait for to be doneLoadingAnswers
        if(this.doneLoadingAnswersDom){
           this.displayVotes(data);
        }else{
           this.listenForStatDomAnswersLoaded(data);
        }
 }.bind(this));
}
*/


commando.prototype.taysRemoveListeners =function(el) {
   var elClone = el.cloneNode(true);
       el.parentNode.replaceChild(elClone, el);
}

commando.prototype.doProductDownvote =function(progressEvent,product,mouseEvent) {

    var currentVal= mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent;
      var postData={};
          postData.id=product.id;
          postData.term=this.search;

     if(mouseEvent.target.classList.contains("commando_voted")){
           mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)+1);
           mouseEvent.target.classList.remove("commando_voted");
           makeRequest('POST', this.endpoint+"/product_feedback.php?delete=1&vote=4&product_result_id="+product.product_result_id+"&u="+this.user_id,JSON.stringify(postData)).then(function(data1){
           }.bind(this));
       }else{

           if(mouseEvent.target.parentElement.getElementsByClassName("arrow-up")[0].classList.contains("commando_voted")){
               mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)-2);
           }else{
               mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)-1);
           };
       mouseEvent.target.classList.add("commando_voted");
       mouseEvent.target.parentElement.getElementsByClassName("arrow-up")[0].classList.remove("commando_voted");
       makeRequest('POST', this.endpoint+"/product_feedback.php?vote=4&product_result_id="+product.product_result_id+"&u="+this.user_id,
       JSON.stringify(postData)).then(function(data1){
          var data=JSON.parse(data1);
                product.product_result_id=data.id;    
       }.bind(this));
   }

}


commando.prototype.checkVotingWorked =function(data1) {
      var data=JSON.parse(data1);
      if(data.success !=="true"){
            this.showLoginPopup('comment_feedback');
            //alert("You need to log in to your Grepper account to submit comment feedback.");
            return false;
      }
      return true;
}
commando.prototype.doCommentUpvote =function(progressEvent,comment,mouseEvent) {
      var currentVal= mouseEvent.target.parentElement.getElementsByClassName("comment-commando-voting-number")[0].textContent;
      var postData={};
          postData.comment_id=comment.id;
          //postData.term=this.search;

       if(mouseEvent.target.classList.contains("comment_commando_voted")){
            makeRequest('POST', this.endpoint+"/comment_feedback.php?delete=1&vote=1", JSON.stringify(postData)).then(function(data1){
                if(this.checkVotingWorked(data1)){
                   mouseEvent.target.classList.remove("comment_commando_voted");
                   mouseEvent.target.parentElement.getElementsByClassName("comment-commando-voting-number")[0].textContent=(parseInt(currentVal)-1);
                }
           }.bind(this));
       }else{

           makeRequest('POST', this.endpoint+"/comment_feedback.php?vote=1", JSON.stringify(postData)).then(function(data1){
                   if(this.checkVotingWorked(data1)){
                  //add one if other we are not already down
                   if(mouseEvent.target.parentElement.getElementsByClassName("comment-arrow-down")[0].classList.contains("comment_commando_voted")){
                       mouseEvent.target.parentElement.getElementsByClassName("comment-commando-voting-number")[0].textContent=(parseInt(currentVal)+2);
                   }else{
                       mouseEvent.target.parentElement.getElementsByClassName("comment-commando-voting-number")[0].textContent=(parseInt(currentVal)+1);
                   };
                   mouseEvent.target.classList.add("comment_commando_voted");
                   mouseEvent.target.parentElement.getElementsByClassName("comment-arrow-down")[0].classList.remove("comment_commando_voted");
            }
           }.bind(this));
      }
}
commando.prototype.doCommentDownvote =function(progressEvent,comment,mouseEvent) {

    var currentVal= mouseEvent.target.parentElement.getElementsByClassName("comment-commando-voting-number")[0].textContent;
      var postData={};
          postData.comment_id=comment.id;
          //postData.term=this.search;
     if(mouseEvent.target.classList.contains("comment_commando_voted")){
            makeRequest('POST', this.endpoint+"/comment_feedback.php?delete=1&vote=4",JSON.stringify(postData)).then(function(data1){
                if(this.checkVotingWorked(data1)){
                    mouseEvent.target.parentElement.getElementsByClassName("comment-commando-voting-number")[0].textContent=(parseInt(currentVal)+1);
                    mouseEvent.target.classList.remove("comment_commando_voted");
                }
           }.bind(this));
       }else{
       makeRequest('POST', this.endpoint+"/comment_feedback.php?vote=4&",
       JSON.stringify(postData)).then(function(data1){
            if(this.checkVotingWorked(data1)){
               if(mouseEvent.target.parentElement.getElementsByClassName("comment-arrow-up")[0].classList.contains("comment_commando_voted")){
                   mouseEvent.target.parentElement.getElementsByClassName("comment-commando-voting-number")[0].textContent=(parseInt(currentVal)-2);
               }else{
                   mouseEvent.target.parentElement.getElementsByClassName("comment-commando-voting-number")[0].textContent=(parseInt(currentVal)-1);
               };
               mouseEvent.target.classList.add("comment_commando_voted");
               mouseEvent.target.parentElement.getElementsByClassName("comment-arrow-up")[0].classList.remove("comment_commando_voted");
            }
       }.bind(this));
   }

}



commando.prototype.doProductUpvote =function(progressEvent,product,mouseEvent) {
      var currentVal= mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent;

      var postData={};
          postData.id=product.id;
          postData.term=this.search;

       if(mouseEvent.target.classList.contains("commando_voted")){
           mouseEvent.target.classList.remove("commando_voted");
           mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)-1);
           makeRequest('POST', this.endpoint+"/product_feedback.php?delete=1&vote=1&product_result_id="+product.product_result_id+"&u="+this.user_id, JSON.stringify(postData)).then(function(data1){
 
           }.bind(this));
       }else{
          //add one if other we are not already down
           if(mouseEvent.target.parentElement.getElementsByClassName("arrow-down")[0].classList.contains("commando_voted")){
               mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)+2);
           }else{
               mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)+1);
           };
           mouseEvent.target.classList.add("commando_voted");
           mouseEvent.target.parentElement.getElementsByClassName("arrow-down")[0].classList.remove("commando_voted");
           makeRequest('POST', this.endpoint+"/product_feedback.php?vote=1&product_result_id="+product.product_result_id+"&u="+this.user_id, JSON.stringify(postData)).then(function(data1){

              var data=JSON.parse(data1);
                product.product_result_id=data.id;    
           }.bind(this));
      }
}


commando.prototype.doUpvote =function(progressEvent,answer,mouseEvent) {

      var postData={};
          postData.id=answer.id;
          postData.term=this.search;
          postData.isRequestedExtraAnswer=answer.isRequestedExtraAnswer;
          postData.isExtraAnswer=answer.isExtraAnswer;
          postData.results = this.resultsURLS;

       if(mouseEvent.target.classList.contains("commando_voted")){

            this.doUpvoteUIRemoveVote(mouseEvent);
           makeRequest('POST', this.endpoint+"/feedback.php?delete=1&vote=1&search_answer_id="+answer.search_answer_id+"&search_answer_result_id="+answer.search_answer_result_id+"&u="+this.user_id, JSON.stringify(postData)).then(function(data1){
           var data=JSON.parse(data1);
               answer.search_answer_result_id=data.id;   
                  if(data.subscription_expired){
                        this.showNeedsPaymentBox(data.subscription_expired_text);
                  }else if(data.success==false && data.reason=="Unauthorized"){
                    this.doUpvoteUIAddVote(mouseEvent);
                    this.showLoginPopup('vote');
                 } 
 
           }.bind(this));
       }else{
          //add one if other we are not already down
            this.doUpvoteUIAddVote(mouseEvent);
           makeRequest('POST', this.endpoint+"/feedback.php?version=2&vote=1&search_answer_id="+answer.search_answer_id+"&search_answer_result_id="+answer.search_answer_result_id+"&u="+this.user_id, JSON.stringify(postData)).then(function(data1){
            var data=JSON.parse(data1);
            answer.search_answer_result_id=data.id;    
             if(data.subscription_expired){
                this.showNeedsPaymentBox(data.subscription_expired_text);
             }else if(data.success==false && data.reason=="Unauthorized"){
                this.doUpvoteUIRemoveVote(mouseEvent);
                this.showLoginPopup('vote');
             }else if(data.show_show_modal){
               // this.doUpvoteUIRemoveVote(mouseEvent);
                this.showShareGrepperModal();
             }

             }.bind(this));
      }
}

commando.prototype.doUpvoteUIRemoveVote =function(mouseEvent) {
    var currentVal= mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent;
           mouseEvent.target.classList.remove("commando_voted");
           mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)-1);
}
commando.prototype.doUpvoteUIAddVote =function(mouseEvent) {
    var currentVal= mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent;
       if(mouseEvent.target.parentElement.getElementsByClassName("arrow-down")[0].classList.contains("commando_voted")){
           mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)+2);
       }else{
           mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)+1);
       };
       mouseEvent.target.classList.add("commando_voted");
       mouseEvent.target.parentElement.getElementsByClassName("arrow-down")[0].classList.remove("commando_voted");

}

commando.prototype.doDownvote =function(progressEvent,answer,mouseEvent) {

      var postData={};
          postData.id=answer.id;
          postData.term=this.search;
          postData.isRequestedExtraAnswer=answer.isRequestedExtraAnswer;
          postData.isExtraAnswer=answer.isExtraAnswer;

     if(mouseEvent.target.classList.contains("commando_voted")){
     
            this.doDownvoteUIRemoveVote(mouseEvent);
           makeRequest('POST', this.endpoint+"/feedback.php?delete=1&vote=4&search_answer_id="+answer.search_answer_id+"&search_answer_result_id="+answer.search_answer_result_id+"&u="+this.user_id,JSON.stringify(postData)).then(function(data1){

        var data=JSON.parse(data1);
            answer.search_answer_result_id=data.id;    
           //not on downvotes
           //if(data.subscription_expired){
           //   this.showNeedsPaymentBox(data.subscription_expired_text);
           //}
              if(data.success==false && data.reason=="Unauthorized"){
                    this.doDownvoteUIAddVote(mouseEvent);
                    this.showLoginPopup('vote');
               }
           }.bind(this));
       }else{

        this.doDownvoteUIAddVote(mouseEvent);
       makeRequest('POST', this.endpoint+"/feedback.php?vote=4&search_answer_id="+answer.search_answer_id+"&search_answer_result_id="+answer.search_answer_result_id+"&u="+this.user_id,
      JSON.stringify(postData)).then(function(data1){
        var data=JSON.parse(data1);
            answer.search_answer_result_id=data.id;    
           //not on downvotes
           //if(data.subscription_expired){
           //   this.showNeedsPaymentBox(data.subscription_expired_text);
           //}
           if(data.success==false && data.reason=="Unauthorized"){
                this.doDownvoteUIRemoveVote(mouseEvent);
                this.showLoginPopup('vote');
           }     
       }.bind(this));
   }
}

commando.prototype.doDownvoteUIRemoveVote =function(mouseEvent) {
  var currentVal= mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent;
      mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)+1);
       mouseEvent.target.classList.remove("commando_voted");

}
commando.prototype.doDownvoteUIAddVote =function(mouseEvent) {
  var currentVal= mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent;
      //add one if other we are not already down
       if(mouseEvent.target.parentElement.getElementsByClassName("arrow-up")[0].classList.contains("commando_voted")){
           mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)-2);
       }else{
           mouseEvent.target.parentElement.getElementsByClassName("commando-voting-number")[0].textContent=(parseInt(currentVal)-1);
       };
       mouseEvent.target.classList.add("commando_voted");
       mouseEvent.target.parentElement.getElementsByClassName("arrow-up")[0].classList.remove("commando_voted");
}


commando.prototype.youComSetupTabListeners =function(){
//  this.youTabListener= setInterval(function(){
//     var allTab= document.querySelector('[data-testid="All-tab"]');
//     if(allTab){
//          clearInterval(this.youTabListener);
//          allTab.addEventListener('click', function() {
//                this.runYouComSearch();
//          }.bind(this));
//     }
//   }.bind(this), 10);

//    setTimeout(function(){
//          clearInterval(this.youTabListener);

//    }.bind(this), 4000);
    const observer = new MutationObserver((mutationsList, observer) => {
        for (let mutation of mutationsList) {
            if (mutation.type === 'childList') {
                // Check if the URL has changed
                if (window.location.href !== this.currentUrl) {
                    this.currentUrl = window.location.href;
                    //console.log("TAYLOOOOOOOOOOOOOOOOR -URL changed to", currentUrl);
                    //alert("url change");
                    var tbm = getParameterByName("tbm");
                    if(tbm){
                        //return false;
                         this.removeGrepperResultsFromYouCom();
                    }else{
                        //alert("running  you com search");
                         this.runYouComSearch();
                    }
                }
            }
        }
    });

    this.currentUrl = window.location.href;
    observer.observe(document, { childList: true, subtree: true });


}


commando.prototype.getStatsDomYouCom =function() {
        console.log("Getting stats dom");
       if(!this.statsDom){
            this.statsDom=document.querySelector('[data-testid="app-mainline"]');
            if(this.statsDom && this.statsDom.classList.contains("you_grepper_holder")){
                this.statsDom=false;

                console.log("containts grepper class");
                return false;
            }
        }
        if(!this.statsDom){
            return false;    
        }else{
            this.statsDom.classList.add("you_grepper_holder");
        }
        console.log("got it");
        return this.statsDom;
}

commando.prototype.getStatsDom =function() {
    if(this.searchEngineId==2){
        return false;
    }
    if(!this.statsDom){
        this.statsDom=document.getElementById("search");
    }
    if(!this.statsDom){
        return false;    
    }
    return this.statsDom;
}

commando.prototype.getStatsDomAfterAllResults =function() {
    if(this.searchEngineId==2){
        return false;
     // if(!this.statsDom){
     //     this.statsDom=document.querySelector('[data-testid="app-mainline"]');
     // }
     // if(!this.statsDom){
     //     return false;    
     // }

     // if(this.stateDomLoadedNoResults > 15){
     //     return this.statsDom;   
     // }

     // //var results = document.querySelectorAll("div#search div.g div.yuRUbf a");
     // var results=this.statsDom.querySelectorAll('[data-testid="web-results"]');

     // const filteredResults = Array.from(results).filter(element => {
     //           return element.querySelector('a[href]');
     // });

     // if(!filteredResults){
     //     this.stateDomLoadedNoResults+=1;
     //     return false;
     // }
     // //6 or more results
     // if(filteredResults.length < 7){
     //     this.stateDomLoadedNoResults+=1;
     //     return false;    
     // }
     // return this.statsDom;

    }else{
        if(!this.statsDom){
            this.statsDom=document.getElementById("search");
        }
        //we need this otherwise count will continue w/out statsDom
        if(!this.statsDom){
            return false;    
        }

        //just finish it
        if(this.stateDomLoadedNoResults > 15){
            return this.statsDom;   
        }
        //var results = document.querySelectorAll("div#search div.g div.r>a");
        //this lets us know when dom is done 
        //this hosuld match other querySelector All in get Answers 2
        var results = document.querySelectorAll("div#search div.g div.yuRUbf a");


        if(!results){
            this.stateDomLoadedNoResults+=1;
            return false;
        }
        //6 or more results
        if(results.length < 7){
            this.stateDomLoadedNoResults+=1;
            return false;    
        }
        return this.statsDom;
    }
}


//Ithiswill now guess the language and Load the needed modes javascript
commando.prototype.languangeNametoTaysCodeMirrorName =function(l,callback) {
  var mode =["javascript"];

  if(l === "javascript"){ l="text/javascript" ; mode=["javascript"];}
  if(l === "php"){ l="text/x-php" ; mode=["clike","javascript","htmlmixed","css","php"];}
  if(l === "java"){ l="text/x-java" ;mode=["clike"];  }
  if(l === "csharp"){ l="text/x-csharp" ;mode=["clike"];  }
  if(l === "python"){ l="text/x-python" ;mode=["python"];  }
  if(l === "swift"){ l="text/x-swift" ;mode=["swift"];  }
  if(l === "objectivec"){ l="text/x-objectivec" ;mode=["clike"];}
  if(l === "cpp"){ l="text/x-c++src" ;mode=["clike"];  }
  if(l === "c"){ l="text/x-csrc" ;mode=["clike"];  }
  if(l === "css"){ l="text/css" ;mode=["css"];  }
  if(l === "html"){ l="text/html" ;mode=["xml","javascript","css","htmlmixed"];  }
  if(l === "shell"){ l="text/x-sh";mode=["shell"];  }
  if(l === "sql"){ l="text/x-mysql";mode=["sql"];  }
  if(l === "typescript"){ l="application/typescript";mode=["javascript"];  }
  if(l === "ruby"){ l="text/x-ruby" ;mode=["ruby"];  }
  if(l === "kotlin"){ l="text/x-kotlin" ;mode=["clike"];  }
  if(l === "go"){ l="text/x-go";mode=["go"];  }
  if(l === "assembly"){ l="text/x-gas";mode=["gas"]; }
  if(l === "r"){ l="text/x-rsrc";mode=["r"]; }
  if(l === "vb"){ l="text/x-vb";mode=["vb"]; }
  if(l === "scala"){ l="text/x-scala";mode=["clike"]; }
  if(l === "rust"){ l="text/x-rust";mode=["rust"]; }
  if(l === "dart"){ l="text/x-dart";mode=["dart"]; }
  if(l === "elixir"){ l="text/javascript";mode=["javascript"]; }
  if(l === "clojure"){ l="text/x-clojure";mode=["clojure"]; }
  if(l === "webassembly"){ l="text/javascript";mode=["javascript"]; }
  if(l === "fsharp"){ l="text/x-fsharp";mode=["mllike"]; }
  if(l === "erlang"){ l="text/x-erlang";mode=["erlang"]; }
  if(l === "haskell"){ l="text/x-haskell";mode=["haskell"]; }
  if(l === "matlab"){ l="text/javascript";mode=["javascript"]; }
  if(l === "cobol"){ l="text/x-cobol";mode=["cobol"]; }
  if(l === "fortran"){ l="text/x-fortran";mode=["fortran"]; }
  if(l === "scheme"){ l="text/x-scheme";mode=["scheme"]; }
  if(l === "perl"){ l="text/x-perl";mode=["perl"]; }
  if(l === "groovy"){ l="text/x-groovy";mode=["groovy"]; }
  if(l === "lua"){ l="text/x-lua";mode=["lua"]; }
  if(l === "julia"){ l="text/x-julia";mode=["julia"]; }
  if(l === "delphi"){ l="text/javascript";mode=["javascript"]; }
  if(l === "abap"){ l="text/javascript";mode=["javascript"]; }
  if(l === "lisp"){ l="text/x-common-lisp";mode=["commonlisp"]; }
  if(l === "prolog"){ l="text/javascript";mode=["javascript"]; }
  if(l === "pascal"){ l="text/x-pascal";mode=["pascal"]; }
  if(l === "postscript"){ l="text/javascript";mode=["javascript"]; }
  if(l === "smalltalk"){ l="text/x-stsrc";mode=["smalltalk"]; }
  if(l === "actionscript"){ l="text/javascript";mode=["javascript"]; }
  if(l === "basic"){ l="text/javascript";mode=["javascript"]; }
  if(l === "powershell"){ l="application/x-powershell";mode=["powershell"]; }
  if(l === "solidity"){ l="text/javascript";mode=["javascript"]; }
  if(l === "gdscript"){ l="text/javascript";mode=["javascript"]; }
  if(l === "excel"){ l="text/javascript";mode=["javascript"]; }



    var total=0;
    for(var i=0;i<mode.length;i++){
        this.injectScript('codemirror/mode/'+mode[i]+'/'+mode[i]+'.js', 'body', function(){
            total++;
            if(total === mode.length){
                callback(l);     
            }
        });
    }
  
}


commando.prototype.showLoginPopup = function(action_type){
    action_type = (typeof action_type !== 'undefined') ?  action_type : 'add_answer'; 

 let taysPopup = document.createElement("div");
     taysPopup.classList.add("tays_popup")
     taysPopup.classList.add("tays_popup_close_on_click")
     taysPopup.setAttribute("id","grepper-editor");

    chrome.runtime.onMessage.addListener(function(message){
       if(message.action ==="GrepperUserRegisteredOrLogin"){
            this.user_id = message.grepper_user_id;
            this.access_token=message.access_token;
            localStorage.setItem("grepper_user_id",this.user_id);
            localStorage.setItem("grepper_access_token",message.access_token);
            this.closeEditor();
            if(window.grepperLoginPopupWindow){
                window.grepperLoginPopupWindow.close();
            }
       }
    }.bind(this));

 let taysPopupInner = document.createElement("div");
     taysPopupInner.classList.add("tays_popup_inner_main_page")
     taysPopup.appendChild(taysPopupInner);

 let taysPopupCloseButton = document.createElement("div");
     taysPopupCloseButton.classList.add("tays_popup_close_button")
     taysPopupCloseButton.textContent="×";
     taysPopupInner.appendChild(taysPopupCloseButton);

     taysPopup.addEventListener('click',function(el){
         if(el.target == taysPopup){
            this.closeEditor();
         }
     }.bind(this));

     taysPopupCloseButton.addEventListener('click',function(){
         this.closeEditor();
     }.bind(this));

 var taysPopupHeader1 = document.createElement("div");
     taysPopupHeader1.classList.add("tays_popup_header1")
     taysPopupHeader1.textContent="Grepper Log in Required";
     taysPopupInner.appendChild(taysPopupHeader1);

 var taysPopupInnerContent = document.createElement("div");
     taysPopupInnerContent.classList.add("tays_popup_inner_content_plugin")

     taysPopupInner.appendChild(taysPopupInnerContent);
 
    var taysPLoginRequired = document.createElement("div");
        taysPLoginRequired.classList.add("tays_grp_login_required");

        taysPopupInnerContent.appendChild(taysPLoginRequired);
    var taysPLoginRequiredText = document.createElement("div");
        taysPLoginRequiredText.classList.add("tays_grp_login_required_text");
        if(!action_type || action_type=="add_answer"){
            taysPLoginRequiredText.textContent="You will need to log in to your Grepper account before you can add an answer.";
        }else if(action_type=='vote'){
            taysPLoginRequiredText.textContent="You will need to log in to your Grepper account before you can vote on answers.";
        }else if(action_type =='answer_terms'){
            taysPLoginRequiredText.textContent="You will need to log in to your Grepper account before you can edit answer terms.";
        }else if(action_type =='comment_feedback'){
            taysPLoginRequiredText.textContent="You need to log in to your Grepper account to submit comment feedback.";
        }else if(action_type =='add_comment'){
            taysPLoginRequiredText.textContent="You need to log in to your Grepper account to add a comment.";
        }else if(action_type =='perform_action'){
            taysPLoginRequiredText.textContent="You need to log in to your Grepper account to perform this action.";
        }else if(action_type =='add_writeup'){
            taysPLoginRequiredText.textContent="You will need to log in to your Grepper account before you can add a Writeup.";
        }


        taysPLoginRequired.appendChild(taysPLoginRequiredText);


    var taysPLoginRequiredButton = document.createElement("a");
        taysPLoginRequiredButton.classList.add("grp_grepper_button1");

        taysPLoginRequiredButton.classList.add("tays_grp_login_required_button");
        taysPLoginRequiredButton.textContent="Log in";
        taysPLoginRequiredButton.addEventListener('click',function(){
        var url=this.web_endpoint+'/app/register.php?is_login=true';
        window.grepperLoginPopupWindow=window.open(url,'winname','directories=no,titlebar=no,toolbar=no,location=no,status=no,menubar=no,scrollbars=no,resizable=no,width=400,height=580');
        }.bind(this));

        taysPLoginRequired.appendChild(taysPLoginRequiredButton);


    let answerTermPopupBottom  = document.createElement("div");
        answerTermPopupBottom.classList.add("answer_term_popup_bottom")
        taysPopupInner.appendChild(answerTermPopupBottom);

    let answerTermPopupBottomButton  = document.createElement("button");
        answerTermPopupBottomButton.classList.add("answer_term_popup_bottom_button")
        answerTermPopupBottomButton.textContent="Close";
        answerTermPopupBottomButton.addEventListener("click",function(){
         this.closeEditor();
        }.bind(this));
        answerTermPopupBottom.appendChild(answerTermPopupBottomButton);

    var removeMe = document.getElementById("grepper-editor");
    if(removeMe){
	    removeMe.parentNode.removeChild(removeMe);
    }
    document.body.appendChild(taysPopup);

}

commando.prototype.showLoginIfNot = function(){
  return new Promise(function (resolve, reject) {
    makeRequest('GET',this.endpoint+"/check_auth_simple.php").then(function(d){
            var stats = JSON.parse(d);
            if(!stats.success && stats.reason=="Unauthorized"){
                this.showLoginPopup();
            }
            this.user_data=stats;
            resolve();
    }.bind(this));
  }.bind(this));
}

commando.prototype.buildTeamsHolder =function(editingAnswer,isEditing,languageGuessDisplayHolder) {
 //add the team options 
    this.teams=[];
    //handle when updating too
    var teamAnswerId="";
    if(isEditing){
        teamAnswerId="&answer_id="+editingAnswer.id;
    }
    makeRequest('GET', this.endpoint+"/get_my_teams.php?u="+this.user_id+teamAnswerId).then(function(data){
     this.teams=JSON.parse(data);
     if(this.teams.length > 0){

         this.teamsHolder = document.createElement("div");
         this.teamsHolder.setAttribute("id","grepper_teams_icon_holder");
         this.teamIcons=[];
         for(var i=0;i<this.teams.length;i++){
         this.teamIcons[i]= document.createElement("div");
         this.teamIcons[i].classList.add("grepper_team_select_icon_holder");
         this.teamIcons[i].setAttribute("grepper_team_name",this.teams[i].name);
         this.teamIcons[i].setAttribute("grepper_team_id",this.teams[i].id);

         if(this.teams[i].add_to_team){
             this.teamIcons[i].classList.add("grepper_team_icon_active");
             this.teamIcons[i].title="Adding answer to team "+this.teams[i].name;
         }else{
             this.teamIcons[i].title="Select to add answer to team "+this.teams[i].name;
         }

          let old_this=this;
         this.teamIcons[i].addEventListener('click',function(){
                if(parseInt(old_this.user_data.f_teams) !=1){
                    old_this.showGrepperProRequired("Teams require a Grepper Professional subscription plan. Unlock the full power of Grepper with a Professional Subscription!");
                }else{
                     if(this.classList.contains("grepper_team_icon_active")){
                        this.classList.remove("grepper_team_icon_active");
                        this.title="Select to add answer to team "+this.getAttribute("grepper_team_name");
                     }else{
                        this.classList.add("grepper_team_icon_active");
                        this.title="Adding answer to team "+this.getAttribute("grepper_team_name");
                     }
                }
         });

            var img=  document.createElement("img");
                img.src="https://www.grepper.com/team_images/50_50/"+this.teams[i].profile_image;

            this.teamIcons[i].appendChild(img);
            this.teamsHolder.appendChild(this.teamIcons[i]);
         }


        languageGuessDisplayHolder.appendChild(this.teamsHolder);
        languageGuessDisplayHolder.style.marginTop="5px";

    }
    }.bind(this));
};

commando.prototype.setupSourceInput=function(isEditing, editingAnswer){

    var that=this;
    this.taysPopupSourceHolder = document.createElement("div");
    this.taysPopupSourceHolder.setAttribute("id","tays_popup_source_holder_2");

    this.taysPopupSourceHolderLabel = document.createElement("span");
    this.taysPopupSourceHolderLabel.textContent="Source:";
    this.taysPopupSourceHolderLabel.setAttribute("id","tays_popup_source_holder_label_2");
    this.taysPopupSourceHolder.appendChild(this.taysPopupSourceHolderLabel);

    //add in the source input 
    this.addSourceButton = document.createElement("a");
    this.addSourceButton.textContent = "Add Source";
    this.addSourceButton.title = "Add Source";
    this.addSourceButton.setAttribute("id","tays_add_source_button_2");

    this.taysPopupSourceText = document.createElement("span");
    this.taysPopupSourceText.setAttribute("id","tays_popup_source_text_2");
    this.taysPopupSourceText.title = "Edit Source";

    this.taysPopupSourceInput = document.createElement("input");
    //this.taysPopupSourceInput.value=window.location.href;
    this.taysPopupSourceInput.setAttribute("id","tays_popup_source_input_2");
    this.taysPopupSourceInput.setAttribute("placeholder","http://www.your-source-website.com");

    this.taysPopupSourceInputDelete = document.createElement("span");
    this.taysPopupSourceInputDelete.setAttribute("id","tays_popup_source_delete_button_2");
    this.taysPopupSourceInputDelete.textContent="x";
    this.taysPopupSourceInputDelete.title = "Delete Source";
    this.taysPopupSourceInputDelete.style.display = "none";

    this.taysPopupSourceInputCheck = document.createElement("span");
    this.taysPopupSourceInputCheck.setAttribute("id","tays_popup_source_check_button_2");
    this.taysPopupSourceInputCheck.textContent="✓";
    this.taysPopupSourceInputCheck.title = "Set Source";
    this.taysPopupSourceInputCheck.style.display = "none";

    this.taysPopupSourceHolder.appendChild(this.addSourceButton);
    this.taysPopupSourceHolder.appendChild(this.taysPopupSourceText);
    this.taysPopupSourceHolder.appendChild(this.taysPopupSourceInput);
    this.taysPopupSourceHolder.appendChild(this.taysPopupSourceInputCheck);
    this.taysPopupSourceHolder.appendChild(this.taysPopupSourceInputDelete);


    this.addSourceButton.addEventListener('click',function(){
        that.addSourceButton.style.display="none";
        that.taysPopupSourceHolderLabel.style.display="inline-block";
        that.taysPopupSourceText.style.display="none";
        that.taysPopupSourceInput.style.display="inline-block";
        that.taysPopupSourceInputDelete.style.display="inline-block";
        that.taysPopupSourceInputCheck.style.display="inline-block";
        that.taysPopupSourceInput.focus();
    });

    this.taysPopupSourceText.addEventListener('click',function(){
        that.taysPopupSourceText.style.display="none";
        that.taysPopupSourceInput.style.display="inline-block";
        that.taysPopupSourceInputDelete.style.display="inline-block";
        that.taysPopupSourceInputCheck.style.display="inline-block";
        that.taysPopupSourceInput.focus();
    });

    //Basically clearing this input out
    this.taysPopupSourceInputDelete.addEventListener('click',function(){
            that.taysPopupSourceInput.value = '';
            that.taysPopupSourceText.textContent = that.taysPopupSourceInput.value;
            that.taysPopupSourceText.style.display="none";
            that.taysPopupSourceInput.style.display="none";
            that.taysPopupSourceInputDelete.style.display="none";
            that.taysPopupSourceInputCheck.style.display="none";
            that.taysPopupSourceHolderLabel.style.display="none";
            that.addSourceButton.style.display="inline-block";
    });

    this.taysPopupSourceInputCheck.addEventListener('click',function(){
        doneSettingsSource();
    });

    this.taysPopupSourceInput.addEventListener('keyup',function(event){
        if (event.key === "Enter") {
            doneSettingsSource();
        }
    });

   function doneSettingsSource(){
    if(!that.taysPopupSourceInput.value){
            that.taysPopupSourceText.textContent = that.taysPopupSourceInput.value;
            that.taysPopupSourceText.style.display="none";
            that.taysPopupSourceInput.style.display="none";
            that.taysPopupSourceInputDelete.style.display="none";
            that.taysPopupSourceInputCheck.style.display="none";
            that.taysPopupSourceHolderLabel.style.display="none";
            that.addSourceButton.style.display="inline-block";
        }else{
            if(that.isValidSource(that.taysPopupSourceInput.value)){
                that.taysPopupSourceText.textContent = that.maxLength(that.taysPopupSourceInput.value,64);
                that.taysPopupSourceText.style.display="inline-block";
                that.taysPopupSourceInput.style.display="none";
                that.taysPopupSourceInputDelete.style.display="none";
                that.taysPopupSourceInputCheck.style.display="none";
            }else{
                alert("Hmm, that source is not a valid URL. Be sure to use full url. ex: http://www.mywebsite.com/mypage.php");
            }
        }
   
    }


    if(isEditing && editingAnswer.source_url){
       this.taysPopupSourceText.textContent = this.maxLength(editingAnswer.source_url,64);
       this.taysPopupSourceInput.value = editingAnswer.source_url;
       this.taysPopupSourceText.style.display="inline-block";
       this.taysPopupSourceInput.style.display="none";
       this.taysPopupSourceInputDelete.style.display="none";
       this.taysPopupSourceInputCheck.style.display="none";
       this.addSourceButton.style.display="none";
       this.taysPopupSourceHolderLabel.style.display="inline-block";
    }

}

commando.prototype.displayAnswerBox =function(editingAnswer,suggestingEdit) {

    this.simpleAnswerBoxHolder = document.createElement("div");
    this.simpleAnswerBoxHolder.setAttribute("id","grepper_simple_answer_box_holder");

    if(this.searchEngineId == 2){
        this.statsDom.insertBefore(this.simpleAnswerBoxHolder,this.statsDom.childNodes[1]);
        this.grepperDomElements.push(this.simpleAnswerBoxHolder);
    }else{
        this.statsDom.insertBefore(this.simpleAnswerBoxHolder,this.statsDom.childNodes[0]);
    }
    
    suggestingEdit = typeof suggestingEdit !== 'undefined' ? suggestingEdit : false;
    //prompt user if they have put in answer and are leaving w/out saving 
    window.onbeforeunload = function(){
        var answer=this.myTaysCodeMirror.getValue();
        if(editingAnswer || answer || this.uploadedVideoName){
            return 'Unsaved Grepper answer, are you sure you want to leave?';
        }
    }.bind(this);

    this.showLoginIfNot();

    var isEditing=false;
    if((typeof editingAnswer) !== 'undefined'){
       isEditing=true; 
    }

    if(this.isWrittingAnswer){
        return;    
    }

    this.isWrittingAnswer=true;
    this.codeResults = document.createElement("textarea");

    if(isEditing){
        this.codeResults.textContent=editingAnswer.answer;    
    }
    
    //this.codeResults.setAttribute("id","commando_code_block_answer");
    //this.statsDom.insertBefore(this.codeResults,this.statsDom.childNodes[0]);
    this.simpleAnswerBoxHolder.appendChild(this.codeResults);

    this.guessCodeLanguage(function(languageGuessRaw){

    if(isEditing && editingAnswer.language){
        languageGuessRaw = editingAnswer.language;
    }

    this.languangeNametoTaysCodeMirrorName(languageGuessRaw,function(mimeType){
   
    this.myTaysCodeMirror = TaysCodeMirror.fromTextArea(this.codeResults,{
                lineNumbers: true,
                theme:"prism-okaidia",
                //theme:"midnight",
                mode: mimeType,
                viewportMargin: Infinity
    });


    this.languageGuessDisplayHolder = document.createElement("div");
    this.languageGuessDisplayHolder.setAttribute("id","languange_guess_display_holder");
    var answerOptionsTitleEdit= document.createElement("div");
        answerOptionsTitleEdit.classList.add("grepper_answers_options_title_simple_editing");
        answerOptionsTitleEdit.textContent=this.search;
        this.languageGuessDisplayHolder.appendChild(answerOptionsTitleEdit);




    this.languageToSelect(languageGuessRaw);

    //add in the public/private button
    this.publicPrivateHolder = document.createElement("a");
    this.publicPrivateHolder.setAttribute("id","grepper_public_private_holder");

    if(isEditing && editingAnswer.is_private == 1){
        this.publicPrivateHolder.title="Answer is Private. Change to Public.";
        this.publicPrivateHolder.classList.add("grepper_public_private_holder_private");
    }else{
        this.publicPrivateHolder.title="Answer is Public. Change to Private.";
        this.publicPrivateHolder.classList.add("grepper_public_private_holder_public");
    }


    let old_this=this;
    this.publicPrivateHolder.addEventListener('click',function(event){
        if(parseInt(old_this.user_data.f_private_answers) !=1){
                old_this.showGrepperProRequired("Private answers require a Grepper Professional subscription plan. Unlock the full power of Grepper with a Professional subscription!");
        }else{
             if(this.classList.contains("grepper_public_private_holder_public")){
                    this.classList.remove("grepper_public_private_holder_public");
                    this.classList.add("grepper_public_private_holder_private");
                    this.title="Answer is Private. Change to Public.";
             }else{
                    this.classList.remove("grepper_public_private_holder_private");
                    this.classList.add("grepper_public_private_holder_public");
                    this.title="Answer is Public. Change to Private.";
             }

        }
    });

    if(!isEditing){
        this.answerTypeHolder = document.createElement("a");
        this.answerTypeHolder.setAttribute("id","grepper_answer_type_holder_advanced");
        this.answerTypeHolder.title="Switch to advanced code snippet editor";
        this.answerTypeHolder.addEventListener("click",function(){
            var content=this.myTaysCodeMirror.getValue();
            this.switchToAdvancedEditor(content);
        }.bind(this));
        this.languageGuessDisplayHolder.appendChild(this.answerTypeHolder);
    }

     
    this.languageGuessDisplayHolder.appendChild(this.publicPrivateHolder);

    this.languageGuessDisplayHolder.appendChild(this.editorCurrentLanguageSelect);

    this.codeResults.parentNode.insertBefore(this.languageGuessDisplayHolder, this.codeResults);

    //myTaysCodeMirror.setSize(null, 100);
    this.codeResultsSave = document.createElement("button");
    this.codeResultsSave.textContent="Save";
    this.codeResultsSave.setAttribute("id","commando_save_answer");

   

    this.buildTeamsHolder(editingAnswer,isEditing,this.languageGuessDisplayHolder);



    //Save the code results
    this.codeResultsSave.addEventListener('click',function(){

   //var answer=this.codeResults.value;
     var answer=this.myTaysCodeMirror.getValue();
    
        var codeSearch={};
            codeSearch.results=this.resultsURLS;
            codeSearch.search=this.search;

        var data={};
        data.answer=answer;
        data.user_id=this.user_id;
        data.codeSearch=codeSearch;
        data.source=2;
        data.language = this.editorCurrentLanguageSelect.value;

        if(this.publicPrivateHolder.classList.contains("grepper_public_private_holder_private")){
            data.is_private = 1;
        }else{
            data.is_private = 0;
        }

        if(this.uploadedVideoName){
            data.uploaded_video_name = this.uploadedVideoName;
        }else{
            data.uploaded_video_name = "";
        }



        if(this.taysPopupSourceInput.value && this.isValidSource(this.taysPopupSourceInput.value)){
            data.source_url=this.taysPopupSourceInput.value;
        }else{
            data.source_url="";
        }

        if(isEditing){
            data.id=editingAnswer.id;    
        }

        var saveUrl = this.endpoint+"/save_answer.php";
        if(isEditing){
            saveUrl =  this.endpoint+"/update_answer.php";
        }
        if(isEditing && suggestingEdit){
            saveUrl =  this.endpoint+"/suggest_edit.php";
        }

        //save answer to teams
        if(this.teams.length){
             data.team_ids=[];
             for(var i=0;i<this.teamIcons.length;i++){
                 if(this.teamIcons[i].classList.contains("grepper_team_icon_active")){
                     data.team_ids.push(this.teamIcons[i].getAttribute("grepper_team_id"));
                 }
             }
        }
        //
        var spinnerIcon = document.createElement("div"); 
            spinnerIcon.classList.add('grepper_loading_ring');
            this.codeResultsSave.textContent=""
            this.codeResultsSave.appendChild(spinnerIcon);

        
        var spinnerIconC = document.createElement("span"); 
            spinnerIconC.textContent="Saving";
            this.codeResultsSave.appendChild(spinnerIconC);
            this.codeResultsSave.disabled=true;

        makeRequest('POST',saveUrl,JSON.stringify(data)).then(function(responseData){

            //re-enable
            this.codeResultsSave.removeAttribute("disabled");
            this.codeResultsSave.textContent="Save";

            var dataR=JSON.parse(responseData); 

            if(dataR.add_language){
                this.addUserCodeLanguage(dataR.add_language);
            }

            if(!isEditing && dataR.grepper_gold > 0){
                localStorage.setItem("grepper_gold",dataR.grepper_gold);
                localStorage.setItem("grepper_gold_total",dataR.grepper_gold_total);
            }

            if(dataR.success==false && dataR.reason=="Unauthorized"){
                this.showLoginPopup();
                return false;
            }else if(dataR.payment_required){
                var r = confirm("Oops! Looks like you need to activate Grepper, Activate now?");
                if (r == true) {
                    window.open("https://www.grepper.com/checkout/checkout.php", "_blank");
                } 
            }else{
                window.onbeforeunload = null;
                if(!isEditing){
                    localStorage.setItem("grepper_share_last_answer",dataR.answer_id);
                }
                location.reload();
            }
        }.bind(this));


    }.bind(this));




    this.codeResultsSaveHolder = document.createElement("div");
    this.codeResultsSaveHolder.setAttribute("id","commando_save_answer_holder");

    var that=this;

    this.setupSourceInput(isEditing,editingAnswer);

//add the add video button
    this.addVideoButton = document.createElement("div");
    //this.addVideoButton.textContent="Add Video"
    this.addVideoButton.title="Add Video";

    this.addVideoButton.setAttribute("id","grepper_add_video");
    this.addVideoButton.addEventListener('click',function(){
        if(parseInt(this.user_data.f_video_answers) !=1){
            this.showGrepperProRequired("Video answers require a Grepper Professional subscription plan. Unlock the full power of Grepper with a Professional subscription!");
        }else{
            this.settupHelpVideo(); 
        }
    }.bind(this));


    if(localStorage.getItem("grepper_access_token")){
        this.codeResultsSaveHolder.appendChild(this.addVideoButton);
    }

    this.codeResultsSaveHolder.appendChild(this.taysPopupSourceHolder);
    this.codeResultsSaveHolder.appendChild(this.codeResultsSave);


    var clearDiv = document.createElement("div");
        clearDiv.style.clear="both";

    this.codeResultsSaveHolder.appendChild(clearDiv);

    //insertAfter(this.codeResultsSave,myTaysCodeMirror);
    this.codeResults.parentNode.insertBefore(this.codeResultsSaveHolder, this.codeResults.nextSibling.nextSibling);

    //go ahead and show video if we are editing a video answer
    if(isEditing && editingAnswer.video_name){
        this.settupHelpVideo(editingAnswer.video_name);
    }

    this.myTaysCodeMirror.focus();


    }.bind(this));//done getting codemirror mode and loading needed script
    }.bind(this));//done guessing languages
}


commando.prototype.editAdvancedAnswerStart = function(answer,suggestingEdit){

        suggestingEdit = typeof suggestingEdit !== 'undefined' ? suggestingEdit : false;
        this.injectScript('codemirror/lib/codemirror.js', 'body',function(){
        this.injectScript('answer_editor.js', 'body',function(){
                this.disableKeyTriggers=true;
            var gae=new grepperAnswerEditor(this);
                gae.displayAdvancedAnswerEditor(answer,suggestingEdit);
                answer.myDom.style.display = "none";
         }.bind(this));
         }.bind(this));
}

commando.prototype.editAnswerStart = function(answer,suggestingEdit) {

        suggestingEdit = typeof suggestingEdit !== 'undefined' ? suggestingEdit : false;

    //so if we pass answe we are editing it

      this.injectScript('codemirror/lib/codemirror.js', 'body',function(){
               this.displayAnswerBox(answer,suggestingEdit);
               answer.myDom.style.display = "none";
      }.bind(this));

        //e.parentNode.removeChild(e);

     // makeRequest('POST', this.endpoint+"/delete.php?id="+id+"&u="+this.user_id).then(function(data){
     //     location.reload();
     // }.bind(this));
}

commando.prototype.deleteAnswer = function(id) {
        var r = confirm("Are you sure you want to delete this answer?");
        if (r == true) {
                makeRequest('POST', this.endpoint+"/delete.php?id="+id+"&u="+this.user_id).then(function(data){
                location.reload();
            }.bind(this));
        }    
}


commando.prototype.handleResultClick =function(event,that,url) {
     for(var i =0;i<this.answers.length;i++){
         //todo: we currenlty don't have feedback for extra answers
         if(this.answers[i].search_answer_result_id){
             var message = {
                    "action":"sendFeedback",
                    "user_id" :this.user_id,
                    "access_token" :this.access_token,
                    "search_answer_result_id":this.answers[i].search_answer_result_id,
                    "vote":5
             };
            chrome.runtime.sendMessage(message);
        }
     }
}

commando.prototype.setUpResultsClickListener =function(that,element) {
        element.setAttribute("grepper-handle-result-click","1");
        element.addEventListener('click',function(event){
            that.handleResultClick(event,that,element.href);
        });
        element.addEventListener('contextmenu',function(event){
            that.handleResultClick(event,that,element.href);
        });

}
commando.prototype.setUpResultsClickListeners =function() {
    //updating this to all urls
    //var results = document.querySelectorAll("div#search div.g div.r>a");
  //var results = document.querySelectorAll("div#search div.g div.rc a");
  //for(var i=0;i<results.length;i++){
  //    this.setUpResultsClickListener(this,results[i]);
  //}

    //var results = document.querySelectorAll("div#search div.g div.s a");
    var results = document.querySelectorAll("div#search div.g a,div#search div.RzdJxc");
    for(var i=0;i<results.length;i++){
        this.setUpResultsClickListener(this,results[i]);
    }
    setTimeout(function(){
       // var results = document.querySelectorAll("div#search div.g div.r>a");
        //var results = document.querySelectorAll("div#search div.g div.rc a");
        var results = document.querySelectorAll("div#search div.g a,div#search div.RzdJxc");
        for(var i=0;i<results.length;i++){
            if(!results[i].getAttribute("grepper-handle-result-click")){
                this.setUpResultsClickListener(this,results[i]);
            }
        }
    }.bind(this), 1000);
}

commando.prototype.getAnswers2 =function() {

    //1. getting the results
  //var results = document.querySelectorAll("div#search div.g div.rc>a");
  //var results = document.querySelectorAll("div#search div.g>div.rc>div.yuRUbf>a");
    //var results = document.querySelectorAll("div#search div.g>div.tF2Cxc>div.yuRUbf>a");
  //var results = document.querySelectorAll("div#search div.g div.yuRUbf>a,span.x2VHCd");
  var results = document.querySelectorAll("div#search div.g div.yuRUbf a,span.x2VHCd");

  //only push unqique results,
  //be sure to always do this
  for(var i=0;i<results.length;i++){
    if(results[i].tagName=="SPAN"){
        if(results[i].textContent){
            this.resultsURLS.push(results[i].textContent.replace("https://","").replace("http://",""));
        }
    }else{
        if(this.resultsURLS.indexOf(results[i].href) === -1){
            this.resultsURLS.push(results[i].href);
        }
    }
  }


  /*
  var message = {
        "action":"pushHistorySearch",
        "search":this.search,
        "search_time": this.currentTime,
        "results":this.resultsURLS 
  };
  chrome.runtime.sendMessage(message); 
  */
    
    var postData={
        "results":this.resultsURLS,
        "search":this.search,
        "user_id":this.user_id
    };
    
  //2. get votes and try to get better results
    makeRequest('POST', this.endpoint+"/get_answers_2.php?v=2"+this.tifgrpr,JSON.stringify(postData)).then(function(r){

      var results=JSON.parse(r);
      //only display if we have new answers or more answers
      if(!results.answers.length && !results.more_answers.length){
        return;
      }

      this.displayResults2(results);
      this.moreAnswers= results.more_answers;

    //count how many extra answer we have
      var answerIds=[];
      for(var i=0;i<this.answers.length;i++){
         answerIds.push(this.answers[i].id);
      }
      for(var i=0;i<this.moreAnswers.length;i++){
         if(answerIds.indexOf(this.moreAnswers[i].id) === -1){
            this.moreAnswersTotalCount+=1;
         }
      }

     if(this.moreAnswersTotalCount > 0){
        this.doShowMoreAnswersButton();
     }

     //here 
     //currently copy feedback is not being sent for extra answers
     this.setupFeedBackListeners();

    }.bind(this));
 
}

commando.prototype.doShowMoreAnswersButton =function() {
    //we should remove me first if we exist
    var currentShowMoreButton = document.getElementById("tays_add_more_answers_button");
    if(currentShowMoreButton){
        currentShowMoreButton.parentNode.removeChild(currentShowMoreButton);    
    }

    this.showMoreAnswersButton = document.createElement("div");
    this.showMoreAnswersButton.setAttribute("id","tays_add_more_answers_button");
    this.showMoreAnswersButton.textContent="Show "+this.moreAnswersTotalCount+" More Grepper Results";
    if(!this.f_more_results){
        this.showMoreAnswersButton.classList.add("tays_add_more_answers_button_disabled");
    }
     
    if(this.searchEngineId ==2){
        var insertAfterElements=this.statsDom.querySelectorAll('.commando_code_block_outer');
            insertAfterElements[insertAfterElements.length-1].classList.add('grepper_last_normal_answer_no_margin');
            insertAfter(this.showMoreAnswersButton,insertAfterElements[insertAfterElements.length-1]);
            this.grepperDomElements.push(this.showMoreAnswersButton);

    }else{
        if(this.statsDom && this.statsDom.childNodes && this.statsDom.childNodes.length >= 2 && this.statsDom.childNodes[this.statsDom.childNodes.length-2]) {
             this.statsDom.childNodes[this.statsDom.childNodes.length-2].classList.add('grepper_last_normal_answer_no_margin');
        }
        this.statsDom.insertBefore(this.showMoreAnswersButton,this.statsDom.childNodes[this.statsDom.childNodes.length-1]);
    }

    this.showMoreAnswersButton.addEventListener('click',function(){
            if(this.f_more_results){
                if(!this.moreResultsInitiated){
                    for(let i=0;i<this.answers.length;i++){
                     var message = { "action":"sendFeedback", "user_id" :this.user_id,"access_token":this.access_token,"search_answer_result_id":this.answers[i].search_answer_result_id, "vote":10 };
                     chrome.runtime.sendMessage(message);
                    }

                    this.displayResults3Init(this.moreAnswers);
                    this.moreResultsInitiated=true;
                }
                this.toggleMoreAnswersShow();
            }else{

                this.showGrepperProRequired("More Grepper results require a Professional subscription plan. Unlock the full power of Grepper with a Professional subscription!");
            }
        }.bind(this));

}


//run we we want to hide 
commando.prototype.toggleMoreAnswersShow=function(){
    this.showHideMoreAnswersButton.style.display="block";
    this.showMoreAnswersButton.style.display="none";
    for (var i = this.answers.length - 1; i >= 0; i--) {
         if(this.answers[i].isExtraAnswer){
            this.answers[i].myDom.style.display="block";
        }
     }

     this.setLastChildMargin();
}

//run we we want to show 
commando.prototype.toggleMoreAnswersHide=function(){
    this.showHideMoreAnswersButton.style.display="none";
    this.showMoreAnswersButton.style.display="block";
    for (var i = this.answers.length - 1; i >= 0; i--) {
         if(this.answers[i].isExtraAnswer){
            this.answers[i].myDom.style.display="none";
        }
     }
     this.setLastChildMargin();
}

//start video stuff
commando.prototype.showStopVideoButton =function() {
    this.stopVideoButton.style.display="block";
}
commando.prototype.hideStopVideoButton =function() {
    this.stopVideoButton.style.display="none";
}
commando.prototype.hideStartVideoButton =function() {
    this.startVideoButton.style.display="none";
}
commando.prototype.hideVideoDurationHelp =function() {
    this.maxVideoTimeButton.style.display="none";
}
commando.prototype.showVideoDurationHelp =function() {
    this.maxVideoTimeButton.style.display="block";
}




commando.prototype.deleteVideo =function() {
        this.helpVideo.src= "";
        this.uploadedVideoName=false;
        this.videoHolder.style.display="none";
        this.helpVideo.style.display="none";
        this.deleteVideoButton.style.display="none";
        this.makeCircleGrey();
        this.showCircle();
        this.showVideoDurationHelp();
        this.showStartVideoButton(false);
}

commando.prototype.showStartVideoButton =function(hasVideo) {
    if(hasVideo){
        this.startVideoButton.textContent = "Redo Recording";
        this.deleteVideoButton.style.display="block";
    }else{
        this.startVideoButton.textContent = "Start Recording";
        this.deleteVideoButton.style.display="none";
    }
    this.startVideoButton.style.display="block";
}

commando.prototype.stopRecording =function() {
    this.recorder.stop();
    var tracks = this.stream.getTracks();
    tracks.forEach(track => track.stop());
    this.stopTimer();
}

commando.prototype.displayVideoAnswer =function(videoURL,rawSource) {
    rawSource = typeof rawSource !== 'undefined' ? rawSource : false;
    if(rawSource){
        this.helpVideo.src=videoURL;
    }else{
    var answerVideoMP4Source = document.createElement("source");
        answerVideoMP4Source.setAttribute("type", "video/mp4");
        answerVideoMP4Source.setAttribute("src",videoURL+".mp4");

    var answerVideoWebMSource = document.createElement("source");
        answerVideoWebMSource.setAttribute("type", "video/webm");
        answerVideoWebMSource.setAttribute("src",videoURL+".webm");

        this.helpVideo.appendChild(answerVideoMP4Source);
        this.helpVideo.appendChild(answerVideoWebMSource);
    }


        this.helpVideo.style.display="block";
        this.showStartVideoButton(true);
        this.hideStopVideoButton();
        this.makeCircleGrey();
        this.hideCircle();
        this.hideVideoDurationHelp();
}

commando.prototype.completeStoppedRecording =function(e) {
        this.codeResultsSave.disabled=true;
        var videoURL = URL.createObjectURL(e.data);
        //this.helpVideoBlob=e.data;
        this.displayVideoAnswer(videoURL,true);

       var formData = new FormData();
        formData.append("help_video", e.data);

        makeRequest('POST', this.endpoint+"/upload_video.php",formData).then(function(r){
          var fullResult = JSON.parse(r);
            if(fullResult.success){
                this.uploadedVideoName = fullResult.uploaded_video_name;
            }
            this.codeResultsSave.removeAttribute("disabled");
        }.bind(this));
}


commando.prototype.stopTimer=function() {
    clearInterval(this.recodingTimer);
    this.recordCircleInner.textContent="";
}

commando.prototype.startTimer =function() {
    var seconds = 59;
    this.recodingTimer = setInterval(function(){
        this.recordCircleInner.textContent=seconds;
        seconds--;
        if(seconds < 0){
            this.stopRecording();
        }
    }.bind(this), 1000);
}

commando.prototype.makeCircleRed =function() {
    this.recordCircleOuter.style.border="2px solid red";
    this.recordCircleInner.style.background="red";
    this.startTimer();
    //start the timer
}
commando.prototype.makeCircleGrey =function() {
    this.recordCircleOuter.style.border="2px solid #777";
    this.recordCircleInner.style.background="#777777";
    //stop the timer
}
commando.prototype.hideCircle =function() {
    this.recordCircleOuter.style.display="none";
}
commando.prototype.showCircle =function() {
    this.recordCircleOuter.style.display="block";
}

commando.prototype.recordingStarted =function() {

       this.showStopVideoButton();
       this.hideStartVideoButton();
       this.makeCircleRed();
       this.showCircle();
       this.showVideoDurationHelp();
       this.helpVideo.style.display="none";
       this.deleteVideoButton.style.display="none";

 };

commando.prototype.startRecording =function() {
    var that=this;
    var video_track;
    var audio_track; 

navigator.mediaDevices.getDisplayMedia({audio:false,video:true}).then(function (video_stream) {
  navigator.mediaDevices.getUserMedia({audio:true,video:false}).then(function (audio_stream) {
    
        [video_track] = video_stream.getVideoTracks();
        [audio_track] = audio_stream.getAudioTracks();

        video_track.onended = function(){
            that.stopRecording();
        }

        that.stream = new MediaStream([video_track, audio_track]);
            //mimeType : 'video/webm'
         var options = {
            mimeType : 'video/webm'
        };
        that.recorder = new MediaRecorder(that.stream,options);
        that.recorder.start();
        that.recordingStarted();

        that.recorder.addEventListener('dataavailable', function(e){
            that.completeStoppedRecording(e);
        });
  }).catch(function(error){
     //stop the display media
    video_stream.getTracks().forEach(track => track.stop());
    if(error.name =="NotAllowedError"){
        alert("Oops! Chrome can't access your microphone. Click the microphone or camera icon on the right side of your url bar and allow access.");
    }else{
       alert("Oops! Something is off and we can't screen record at this time. Please let us know at support@codegrepper.com");
    }
  });
}).catch(function(error){
    if(error.name =="NotAllowedError"){
        alert("Oops! Chrome does not have access to screen record. Go to System Preferences > Security & Privacy > Privacy > Screen Recording > Check the Chrome checkbox");
    }else{
       alert("Oops! Something is off and we can't screen record at this time. Please let us know at support@codegrepper.com");
    }
});

};


commando.prototype.settupHelpVideo =function(video_name) {

     video_name = typeof video_name !== 'undefined' ? video_name : false;

    if(this.videoHolder){
        this.videoHolder.style.display="block";
        return;
    }


    this.maxVideoTimeButton = document.createElement("div");

    this.maxVideoTimeButton.setAttribute('style', 'white-space: pre;');
    this.maxVideoTimeButton.textContent="Keep it short! Max video duration is 60 seconds.\r\n Note: Use screen recordings for technical queries that can not be answered with a code snippet.";
    this.maxVideoTimeButton.setAttribute("id","commando_max_video_time");
 

    this.startVideoButton = document.createElement("button");
    this.startVideoButton.textContent="Start Recording";
    this.startVideoButton.setAttribute("id","commando_start_recording_button");
    this.startVideoButton.addEventListener('click',function(){
        this.startRecording();
      }.bind(this));

    //stop video button
    this.stopVideoButton = document.createElement("button");
    this.stopVideoButton.textContent="Stop Recording";
    this.stopVideoButton.setAttribute("id","commando_stop_recording_button");
    this.stopVideoButton.addEventListener('click',function(){
        this.stopRecording();
    }.bind(this));

    //Delete/Remove Video Button
    this.deleteVideoButton = document.createElement("a");
    this.deleteVideoButton.textContent="Remove/Delete Video";
    this.deleteVideoButton.setAttribute("id","commando_delete_video_button");
    this.deleteVideoButton.addEventListener('click',function(){
        this.deleteVideo();
    }.bind(this));

    this.recordCircleOuter = document.createElement("div");
    this.recordCircleOuter.setAttribute("id","grepper_record_outer_circle");

    this.recordCircleInner = document.createElement("div");
    this.recordCircleInner.setAttribute("id","grepper_record_inner_circle");
    this.recordCircleOuter.appendChild(this.recordCircleInner);

    this.helpVideo = document.createElement("video");
    this.helpVideo.setAttribute("controls","");
    this.helpVideo.classList.add("grepper_video_element");

    this.videoHolder = document.createElement("div");
    this.videoHolder.setAttribute("id","grepper_video_answer_holder");

    this.videoHolder.appendChild(this.maxVideoTimeButton);
    this.videoHolder.appendChild(this.recordCircleOuter);
    this.videoHolder.appendChild(this.helpVideo);
    this.videoHolder.appendChild(this.startVideoButton);
    this.videoHolder.appendChild(this.stopVideoButton);
    this.videoHolder.appendChild(this.deleteVideoButton);

    this.codeResults.parentNode.insertBefore(this.videoHolder, this.codeResultsSaveHolder);

    if(video_name){
        this.displayVideoAnswer(this.web_endpoint+"/video_uploads/"+video_name);
        this.uploadedVideoName = video_name;
    }

}
//end video stuff

commando.prototype.getVotingHolder =function(answer) {

          var commandoVotingHolder= document.createElement("div");
              commandoVotingHolder.classList.add("commando-voting-holder");
          var upvote= document.createElement("div");
              upvote.classList.add("arrow-up");
              upvote.setAttribute("answer_id",answer.id);
              upvote.addEventListener('click', this.doUpvote.bind(this,event,answer));
              if(answer.i_upvoted == 1){
                upvote.classList.add("commando_voted");
               }

      

          var voteNumber= document.createElement("div");
              voteNumber.classList.add("commando-voting-number");
              voteNumber.textContent=(answer.upvotes-answer.downvotes);

          var downvote= document.createElement("div");
              downvote.classList.add("arrow-down");

              downvote.addEventListener('click', this.doDownvote.bind(this,event,answer));
              if(answer.i_downvoted == 1){
                downvote.classList.add("commando_voted");
              }


    //start tip stuff
    if(this.grepcc_tips_left && this.grepcc_tips_left > 0 && parseInt(answer.user_id) != parseInt(this.user_id)){
         let tipMessage= document.createElement("div");
             tipMessage.classList.add("grepperp_tip_message");
             tipMessage.textContent="Tip "+jsUcfirst(answer.fun_name)+" 1 GREPCC";

        let tipHolder= document.createElement("a");
            tipHolder.classList.add("grepperp_contributor_coin");


            tipHolder.addEventListener('mousedown',function(){
               tipMessage.style.display="none"; 
            });

            tipHolder.addEventListener('mouseenter',function(){
               tipMessage.textContent="Tip "+jsUcfirst(answer.fun_name)+" 1 GREPCC";
               tipMessage.style.display="block"; 
            });

            tipHolder.addEventListener('mouseleave',function(){
               tipMessage.style.display="none"; 
            });

            tipHolder.addEventListener('click',function(){
                  function random(min,max){
                       return Math.round(Math.random() * (max - min)) + min;
                  }

                  let c = document.createElement('div');
                  for (var i=0; i<40; i++) {
                    var styles = 'transform: translate3d(' + (random(-70,70)) + 'px, ' + (random(-70,70)) + 'px, 0) rotate(' + random(0,360) + 'deg);\
                                  background: hsla('+random(0,360)+',100%,50%,1);\
                                  animation: grepperdonatebang 700ms ease-out forwards; \
                                  opacity: 0';

                    var e = document.createElement("i");
                        e.classList.add("grepperp_contributor_coin_confedi")
                    e.style.cssText = styles.toString();
                    c.appendChild(e);
                }
                tipHolder.appendChild(c);
                setTimeout(function(){
                    tipHolder.removeChild(c);
                }, 1000);

            var postData={};
              postData.id=answer.id;
              postData.term=this.search;
              postData.isRequestedExtraAnswer=answer.isRequestedExtraAnswer;
              postData.isExtraAnswer=answer.isExtraAnswer;
              postData.results = this.resultsURLS;

               makeRequest('POST', this.endpoint+"/feedback.php?vote=11&search_answer_id="+answer.search_answer_id+"&search_answer_result_id="+answer.search_answer_result_id+"&u="+this.user_id, JSON.stringify(postData)).then(function(data1){
               var data=JSON.parse(data1);
             if(data.grepcc_tips_left< 1){
                 tipMessage.textContent="Thanks! That was your last tip for today";

                 setTimeout(function(){
                    let tipHolders = document.getElementsByClassName("grepperp_contributor_coin");
                    for(let i=0;i<tipHolders.length;i++){
                        tipHolders[i].classList.add("hide_grepperp_contributor_coin");
                    }
                 },2000);

                 setTimeout(function(){
                    let tipHolders = document.getElementsByClassName("grepperp_contributor_coin");
                    for(let i=0;i<tipHolders.length;i++){
                        tipHolders[i].style.display="none";
                    }
                    let tipMessages = document.getElementsByClassName("grepperp_tip_message");
                    for(let i=0;i<tipMessages.length;i++){
                        tipMessages[i].style.display="none";
                    }
                 },4000);

             }else if(data.grepcc_tips_left == 1){
                tipMessage.textContent="You can tip once more today";
             }else{
                tipMessage.textContent="You have "+data.grepcc_tips_left+" tips left today";
             }

                tipMessage.style.display="block";


               }.bind(this));
            }.bind(this));
           commandoVotingHolder.appendChild(tipHolder);
           commandoVotingHolder.appendChild(tipMessage);
        }

          answer.downvote=downvote;
          answer.upvote=upvote;
          answer.voteNumber=voteNumber;



          commandoVotingHolder.appendChild(upvote);
          commandoVotingHolder.appendChild(voteNumber);
          commandoVotingHolder.appendChild(downvote);


return commandoVotingHolder;


}

commando.prototype.addTeamImage =function(answer,codeResultsOuter) {
        if(answer.is_my_team){
          var teamImageA= document.createElement("a");
              teamImageA.href="https://www.grepper.com/app/team.php?id="+answer.team_id;
              teamImageA.title=answer.team_name+" Team Answer";
              teamImageA.target="_blank";

          var teamImage= document.createElement("img");
              teamImage.src="https://www.grepper.com/team_images/50_50/"+answer.team_profile_image;
              teamImage.classList.add("grepper_team_answer_image");

              teamImageA.appendChild(teamImage);
              codeResultsOuter.appendChild(teamImageA);
        }
};

commando.prototype.buildSourceURLHolder =function(answer) {
          var sourceURLHolder= document.createElement("div");
              sourceURLHolder.setAttribute("id","grepper_source_holder");

              if(!answer.is_promotion){
                sourceURLHolder.textContent = "Source:"
              
            
            var sourceURL= document.createElement("a");
                sourceURL.target="_blank";
                sourceURL.href=answer.source_url;
                sourceURL.textContent = sourceURL.hostname;

                sourceURL.addEventListener('contextmenu',function(event){
                     var message = {
                            "action":"sendFeedback",
                            "user_id" :this.user_id,
                            "access_token" :this.access_token,
                            "search_answer_result_id":answer.search_answer_result_id,
                            "vote":9
                     };
                    chrome.runtime.sendMessage(message);
                }.bind(this));
                sourceURL.addEventListener('click',function(event){
                     var message = {
                            "action":"sendFeedback",
                            "user_id" :this.user_id,
                            "access_token" :this.access_token,
                            "search_answer_result_id":answer.search_answer_result_id,
                            "vote":9
                     };
                    chrome.runtime.sendMessage(message);
                }.bind(this));

              sourceURLHolder.appendChild(sourceURL);
            }else{
             var promoAbout= document.createElement("a");
                 promoAbout.target="_blank";
                 promoAbout.classList.add("grepper_endorced_products_about");
                 promoAbout.href=this.web_endpoint+"/grepper_endorsed_products.php";
                 promoAbout.textContent = "About Grepper Endorsed Products";
                 sourceURLHolder.appendChild(promoAbout);
              }
              return sourceURLHolder;
}

commando.prototype.displayResult =function(answer) {

        if(answer.do_hide4 == 1){
            return;
        }

        var answer_id=answer.id;

        var codeResults = document.createElement("code");
            codeResults.textContent=answer.answer;
            codeResults.classList.add("commando_code_block");

            var languageGuess="javascript";
            if(answer.language){
                languageGuess=answer.language;
            }
            codeResults.classList.add("language-"+languageGuess);

        var codeResultsPre = document.createElement("pre");
            codeResultsPre.classList.add("language-"+languageGuess);
            codeResultsPre.appendChild(codeResults);
            codeResultsPre.classList.add("commando_selectable");
            
        var codeResultsOuter = document.createElement("div");
            codeResultsOuter.classList.add("commando_code_block_outer");
        var answerOptionsHolder=this.buildAnswerOptionsHolder(answer,codeResultsOuter);

            codeResultsOuter.appendChild(answerOptionsHolder);
            codeResultsOuter.appendChild(codeResultsPre);

        //video
        if(answer.video_name){
            var answerVideo = document.createElement("video");
                answerVideo.setAttribute("controls","");
                answerVideo.classList.add("grepper_answer_video_element");
            var answerVideoMP4Source = document.createElement("source");
                answerVideoMP4Source.setAttribute("type", "video/mp4");
                answerVideoMP4Source.setAttribute("src",this.web_endpoint+"/video_uploads/"+answer.video_name+".mp4");
            var answerVideoWebMSource = document.createElement("source");
                answerVideoWebMSource.setAttribute("type", "video/webm");
                answerVideoWebMSource.setAttribute("src",this.web_endpoint+"/video_uploads/"+answer.video_name+".webm");

                answerVideo.appendChild(answerVideoMP4Source);
                answerVideo.appendChild(answerVideoWebMSource);
                codeResultsOuter.appendChild(answerVideo);
        }
            
              
              var sourceURLHolder = this.buildSourceURLHolder(answer);

              //answerOptionsNickname.appendChild(donateButton);

              if(answer.source_url && this.isValidSource(answer.source_url)){
                codeResultsOuter.appendChild(sourceURLHolder);
              }

            //no, voting for now
        var commandoVotingHolder=this.getVotingHolder(answer);
        this.addTeamImage(answer,codeResultsOuter);


         codeResultsOuter.appendChild(commandoVotingHolder);


        
          //// START OF COMMENTS /////
      var showCommentButton = document.createElement("a");
          showCommentButton.classList.add("grepper_show_comment_button");
          showCommentButton.textContent="Comments("+parseInt(answer.t_comments)+")";
      var addCommentButton = document.createElement("a");
          addCommentButton.classList.add("grepper_add_comment_button");
          addCommentButton.textContent="Comment";
          addCommentButton.addEventListener('click',function(){

            if(answer.newCommentHolder){
                answer.newCommentHolder.parentNode.removeChild(answer.newCommentHolder);
                answer.newCommentHolder=false;
                return;
            }
            this.addNewComment(answer,codeResultsOuter);

          }.bind(this));

      var commentButtonHolder = document.createElement("div");
          commentButtonHolder.classList.add("grepper_comments_button_holder");

        var showOrAddButton = (answer.t_comments) ? showCommentButton:addCommentButton;
          answerOptionsHolder.answerOptionsNickname.appendChild(showOrAddButton);

          showCommentButton.addEventListener('click',function(){
              this.getAndShowAnswerComments(answer,codeResultsOuter);
           }.bind(this));
          //// END OF COMMENTS /////

          
          answer.codeResults=[codeResults];
          answer.myDom=codeResultsOuter;

        if(this.searchEngineId==2){

            var insertAfterElements=this.statsDom.querySelectorAll('.commando_code_block_outer');
            if(insertAfterElements.length < 1){
                insertAfter(codeResultsOuter,document.getElementById("youcom_commando_add_answer_button_holder"));
            }else{
                insertAfter(codeResultsOuter,insertAfterElements[insertAfterElements.length-1]);
            }
        }else{
            this.statsDom.insertBefore(codeResultsOuter,this.statsDom.childNodes[this.statsDom.childNodes.length-1]);
        }

        if(this.searchEngineId ==2){
            this.grepperDomElements.push(codeResultsOuter);
        }

        //so dom has been loaded we can get stuff now
        if(this.showWrongAnswerFeedbackButton){
             answerOptionsWrongTerm.style.left = (3+answerOptionsTitle.offsetWidth)+"px";
             answerOptionsWrongTerm.style.display ="block";
        }

        //show comments if coming from web
        if(this.do_show_grepper_comments && this.do_show_grepper_comments == answer.id){
              this.getAndShowAnswerComments(answer,codeResultsOuter);
        }
        
}

commando.prototype.displayProduct =function(i,product) {
  var productDom = document.createElement("div");
      productDom.classList.add("grepper_product_result");

            if(i==0){
                  productDom.classList.add("grepper_first_child");
            }

          var commandoVotingHolder= document.createElement("div");
              commandoVotingHolder.classList.add("grepper_product_voting_holder");
            
          var upvote= document.createElement("div");
              upvote.classList.add("arrow-up");
              upvote.setAttribute("answer_id",product.id);
              upvote.addEventListener('click', this.doProductUpvote.bind(this,event,product));
              if(product.i_upvoted == 1){
                upvote.classList.add("commando_voted");
               }

      

          var voteNumber= document.createElement("div");
              voteNumber.classList.add("commando-voting-number");
              voteNumber.textContent=(product.upvotes-product.downvotes);

          var downvote= document.createElement("div");
              downvote.classList.add("arrow-down");

              downvote.addEventListener('click', this.doProductDownvote.bind(this,event,product));
              if(product.i_downvoted == 1){
                downvote.classList.add("commando_voted");
              }


            commandoVotingHolder.appendChild(upvote);
            commandoVotingHolder.appendChild(voteNumber);
            commandoVotingHolder.appendChild(downvote);

      var productImage = document.createElement("img");
          productImage.src = product.image;

      var productImageLink = document.createElement("a");
          productImageLink.href=this.endpoint+"/visit-product.php?goto="+product.name+"&r="+product.product_result_id;
          productImageLink.target="_blank";
          productImageLink.title="Visit "+product.name;

          productImageLink.appendChild(productImage);

          
          productDom.appendChild(productImageLink);

          productDom.appendChild(commandoVotingHolder);

          this.productsResultHolder.appendChild(productDom); 
}

commando.prototype.displayProducts =function() {
    if(!this.products.length){ return; }

      this.productsResultHolder = document.createElement("div");
      this.productsResultHolder.setAttribute("id","grepper_products_results_holder");

      var productResultsTitleHolder = document.createElement("div");
          productResultsTitleHolder.classList.add("grepper_products_title_holder");

       var productResultsTitleLeft = document.createElement("div");
           productResultsTitleLeft.textContent ="Grepper Rankings for “"+this.search+"”";
           productResultsTitleLeft.classList.add("grepper_products_title_left");

       var productResultsTitleRight = document.createElement("div");
           productResultsTitleRight.textContent ="Product Feedback by ";
           productResultsTitleRight.classList.add("grepper_products_title_right");


       var productResultsTitleRightCommunity = document.createElement("a");
           productResultsTitleRightCommunity.href="https://www.grepper.com/app/index.php";
           productResultsTitleRightCommunity.target="_blank";
           productResultsTitleRightCommunity.textContent="Grepper Dev Community";

           productResultsTitleRight.appendChild(productResultsTitleRightCommunity);

       var productResultsTitleRightCommunitySpace = document.createElement("span");
           productResultsTitleRightCommunitySpace.textContent=" - ";
           productResultsTitleRight.appendChild(productResultsTitleRightCommunitySpace);


       var productResultsTitleRightCommunityLearnMore = document.createElement("a");
           productResultsTitleRightCommunityLearnMore.href="https://www.grepper.com/grepper_products_system.php";
           productResultsTitleRightCommunityLearnMore.target="_blank";
           productResultsTitleRightCommunityLearnMore.textContent="Learn more";
           productResultsTitleRight.appendChild(productResultsTitleRightCommunityLearnMore);




        var clearBoth = document.createElement("div");
           clearBoth.classList.add("grepper_clear_both");



       productResultsTitleHolder.appendChild(productResultsTitleLeft);
       productResultsTitleHolder.appendChild(productResultsTitleRight);
       productResultsTitleHolder.appendChild(clearBoth);
       this.productsResultHolder.appendChild(productResultsTitleHolder);

      this.statsDom.prepend(this.productsResultHolder);

   for(let i=0;i<this.products.length;i++){
      this.displayProduct(i,this.products[i]);
   }

}

commando.prototype.displayWriteups =function() {
    if(!this.writeups.length){
        return
    }

    for(let i=0;i<this.writeups.length;i++){
        this.displayWriteup(this.writeups[i]);
    }
}

commando.prototype.displayWriteup =function(writeup) {

    var answerOptionsHolder= document.createElement("div");
         answerOptionsHolder.classList.add("commando_answers_options_holder");


        var answerOptionsTitle= document.createElement("div");
            answerOptionsTitle.classList.add("grepper_answers_options_title");
            answerOptionsTitle.textContent=writeup.title;
            answerOptionsTitle.title=writeup.title;

        var answerOptionsNickname= document.createElement("span");
            answerOptionsNickname.classList.add("commando_answers_options_nickname");
            var t = writeup.created_at.split(/[- :]/);
            var d = new Date(Date.UTC(t[0], t[1]-1, t[2], t[3], t[4], t[5]));
            var formattedDate=dateToNiceDayString(d);

           var noteHTML= document.createElement("i");

           var userProfileLink= document.createElement("a");
               userProfileLink.target="_blank";
               userProfileLink.href="https://www.grepper.com/profile/"+writeup.profile_slug;

           var dateOnSpan= document.createElement("i");
               dateOnSpan.textContent = " on "+formattedDate+" ";

               noteHTML.textContent="Write-up By ";
               if(this.user_id == writeup.user_id){
                 userProfileLink.textContent = "Me ("+jsUcfirst(writeup.fun_name)+")";
               }else{
                 userProfileLink.textContent = jsUcfirst(writeup.fun_name);
               }

             noteHTML.appendChild(userProfileLink);
             noteHTML.appendChild(dateOnSpan);

            answerOptionsNickname.appendChild(noteHTML);


    answerOptionsHolder.appendChild(answerOptionsTitle);
    answerOptionsHolder.appendChild(answerOptionsNickname);

    let writeup_holder=document.createElement("div");
        writeup_holder.classList.add("grepperp_writeup_holder");

        writeup_holder.addEventListener("click",function(){

           if(this.user_id == writeup.user_id){
               window.open(this.web_endpoint+"/app/writeup.php?id="+writeup.id,'_blank');
            }else{
               window.open(this.web_endpoint+"/writeups/"+writeup.slug,'_blank');
            }
        }.bind(this));

        writeup_holder.appendChild(answerOptionsHolder);

    let writeup_title_holder=document.createElement("div");
        writeup_title_holder.classList.add("grepperp_writeup_title_holder");
        
    let writeup_title=document.createElement("div");
        writeup_title.classList.add("grepperp_writeup_title");
        writeup_title.textContent=writeup.title;

    let writeup_desc=document.createElement("div");
        writeup_desc.classList.add("grepperp_writeup_description");
        writeup_desc.textContent=writeup.description;
        writeup_title_holder.appendChild(writeup_title);
        writeup_title_holder.appendChild(writeup_desc);

    let writeup_img_holder=document.createElement("div");
        writeup_img_holder.classList.add("grepperp_writeup_img_holder");

    let writeup_img=document.createElement("img");
        writeup_img.classList.add("grepperp_writeup_hero_img");
        writeup_img_holder.appendChild(writeup_img);

        if(writeup.hero_image_thumb){
            writeup_img.src=writeup.hero_image_thumb;
        }else{
            writeup_img.src=this.web_endpoint+"/images/grepper_writeup_default.png";
        }

        writeup_holder.appendChild(writeup_img_holder);
        writeup_holder.appendChild(writeup_title_holder);

    let clearBoth = document.createElement("div");
        clearBoth.classList.add("grp_clear_both");

        writeup_holder.appendChild(clearBoth);
        writeup.myDom=writeup_holder;

        //this.statsDom.appendChild(writeup_holder);
        this.statsDom.insertBefore(writeup_holder,this.statsDom.childNodes[this.statsDom.childNodes.length-1]);
}

//this runt the first time around
commando.prototype.displayResults =function() {
       if(this.searchEngineId==2){
            this.showAddAnswerButtonYouCom();
       }

       for(let i=0;i<this.answers.length;i++){
           if(i==1){
                this.displayInlineAd();
           }
           if(this.answers[i].is_advanced){
                this.displayResultAdvanced(this.answers[i]);
           }else{
                this.displayResult(this.answers[i]);
           }
       }
       if(this.answers.length == 1){
            this.displayInlineAd();
       }

       this.displayWriteups();//display the writeups


      this.setLastChildMargin();

      Prism.highlightAll();
      this.showAddAnswerButton();
    
     //also set up more answers stuff
     //count how many extra answer we have
      var answerIds=[];
      for(var i=0;i<this.answers.length;i++){
         answerIds.push(this.answers[i].id);
      }
      for(var i=0;i<this.moreAnswers.length;i++){
         if(answerIds.indexOf(this.moreAnswers[i].id) === -1){
            this.moreAnswersTotalCount+=1;
         }
      }

     if(this.moreAnswersTotalCount > 0){
        this.doShowMoreAnswersButton();
     }

   //if(this.answers.length > 0){
   //      this.setupCopyListener();
   //}
   
     //currently copy feedback is not being sent for extra(more) answers
    this.setupFeedBackListeners();
    this.setupScrollOverflowDownClick();

    //this is for showing grepper gold, show work this point 
    if(parseInt(localStorage.getItem("grepper_gold"))){
        this.showGrepperGoldPopup(parseInt(localStorage.getItem("grepper_gold")),parseInt(localStorage.getItem("grepper_gold_total")));
        localStorage.setItem("grepper_gold",0);
    }


  //if(localStorage.getItem("grepper_share_last_answer")){
  //    //let last_answer_id= localStorage.getItem("grepper_share_last_answer");
  //    let last_answer_id= localStorage.getItem("grepper_share_last_answer");
  //    this.showShareGrepperSocialShareModal(last_answer_id,true);
  //    localStorage.removeItem("grepper_share_last_answer");
  //}


  
}


commando.prototype.buildAnswerOptionsHolder =function(answer,codeResultsOuter) {
      var  answerOptionsHolder= document.createElement("div");
           answerOptionsHolder.classList.add("commando_answers_options_holder");


        var answerOptionsTitle= document.createElement("div");
            answerOptionsTitle.classList.add("grepper_answers_options_title");

        if(answer.is_promotion){
               answerOptionsHolder.classList.add("commando_answers_options_holder_promo");
               answerOptionsTitle.textContent="Endorsed Product: "+answer.term;
               answerOptionsTitle.title="Grepper Endorsed Product For: "+answer.term;

          }else{

            answerOptionsTitle.textContent=answer.term;
            answerOptionsTitle.title=answer.term;
          }
         


        if(answer.hasOwnProperty('banner_ad') && answer.banner_ad){
            var bannerAdHolder=document.createElement("div");
                bannerAdHolder.classList.add('grepper_banner_ad_inline_holder');

            var bannerAd= document.createElement("img");
                bannerAd.classList.add("grepper_banner_ad_inline");
                bannerAd.src=answer.banner_ad.CreativeUrl;
                bannerAd.addEventListener('click',function(){
                   window.open(answer.banner_ad.url, "_blank");
                });

            var bannerAdClose= document.createElement("div");
                bannerAdClose.classList.add('grepper_banner_ad_close');
                bannerAdClose.textContent="✕";
                bannerAdClose.addEventListener('click',function(){
                    bannerAdHolder.parentNode.removeChild(bannerAdHolder);
                });

            var bannerAdUpgrade= document.createElement("a");
                bannerAdUpgrade.classList.add('grepper_banner_ad_upgrade');
                bannerAdUpgrade.textContent="Go Ad-Free";
                bannerAdUpgrade.href="https://www.codegrepper.com/subscriptions.php";

                bannerAdHolder.appendChild(bannerAd);
                bannerAdHolder.appendChild(bannerAdClose);
                bannerAdHolder.appendChild(bannerAdUpgrade);
                codeResultsOuter.appendChild(bannerAdHolder);
        }


        if(this.showWrongAnswerFeedbackButton){

        var answerOptionsWrongTerm= document.createElement("div");
            answerOptionsWrongTerm.classList.add("grepper_answers_options_wrong_term");
            answerOptionsWrongTerm.textContent="!=";

        let answerOptionsWrongTermMessage= document.createElement("a");
            answerOptionsWrongTermMessage.classList.add("grepper_answers_options_wrong_term_message");

            answerOptionsWrongTermMessage.textContent="Mark as wrong answer for my search term";

            answerOptionsWrongTerm.addEventListener('mousedown',function(){
               answerOptionsWrongTermMessage.style.display="none"; 
               this.showIncorrectTermModal(answer);
            }.bind(this));

        let answerOptionsWrongTermMessageHoverTimeout=false;
            answerOptionsWrongTerm.addEventListener('mouseenter',function(){

                if(answerOptionsWrongTermMessageHoverTimeout){
                    clearTimeout(answerOptionsWrongTermMessageHoverTimeout);
                }
                answerOptionsWrongTermMessageHoverTimeout = setTimeout(function() {
                    answerOptionsWrongTermMessage.style.display="block"; 
                    answerOptionsWrongTerm.classList.add("grepper_wrong_answer_feedback_red");
                }, 250);
            });
            answerOptionsWrongTerm.addEventListener('mouseleave',function(){
                if(answerOptionsWrongTermMessageHoverTimeout){
                    clearTimeout(answerOptionsWrongTermMessageHoverTimeout);
                }

                answerOptionsWrongTerm.classList.remove("grepper_wrong_answer_feedback_red");
               answerOptionsWrongTermMessage.style.display="none"; 
            });

            answerOptionsWrongTerm.appendChild(answerOptionsWrongTermMessage);

            }


            //if(parseInt(answer.user_id) === parseInt(this.user_id)){

                answerOptionsTitle.title="Edit Answer Title";
                answerOptionsTitle.classList.add("grepper_clickable_title");
                answerOptionsTitle.addEventListener("click",function(){
                    this.showAnswerTermsModal(answer);
                }.bind(this));
            //}


        var answerOptionsNickname= document.createElement("span");
            answerOptionsNickname.classList.add("commando_answers_options_nickname");

            var t = answer.created_at.split(/[- :]/);
            var d = new Date(Date.UTC(t[0], t[1]-1, t[2], t[3], t[4], t[5]));
            var formattedDate=dateToNiceDayString(d);


           var noteHTML= document.createElement("i");

           var userProfileLink= document.createElement("a");
               userProfileLink.target="_blank";
               userProfileLink.href="https://www.codegrepper.com/profile/"+answer.profile_slug;

           var dateOnSpan= document.createElement("i");
               dateOnSpan.textContent = " on "+formattedDate+" ";
            
               if(answer.is_advanced){
                noteHTML.textContent="By ";
               }else{
                noteHTML.textContent=this.getLanguageFriendlyName(answer.language)+" By ";
               }

               if(this.user_id == answer.user_id){
                 userProfileLink.textContent = "Me ("+jsUcfirst(answer.fun_name)+")";
               }else{
                 userProfileLink.textContent = jsUcfirst(answer.fun_name);
               }

             noteHTML.appendChild(userProfileLink);
             if(!answer.is_promotion){
                noteHTML.appendChild(dateOnSpan);
             }



            answerOptionsNickname.appendChild(noteHTML);






              if(!answer.is_promotion){
              if(answer.donate_link){

                    var donateButton= document.createElement("a");
                        donateButton.target="_blank";
                        donateButton.href=answer.donate_link;
                        donateButton.textContent="Donate";

                      //noteHTML+=" <a target='_blank' href='"++"'>Donate</a>";

                answerOptionsNickname.appendChild(donateButton);
              };
              }

              if(!answer.is_promotion){
                 if(parseInt(answer.user_id) != parseInt(this.user_id)){
                    var thankButton= document.createElement("a");
                        //thankButton.target="_blank";
                        thankButton.classList.add("grepper_plugin_thank_button");
                        //thankButton.href="#";
                        thankButton.textContent="Thank";
                        thankButton.addEventListener("click",function(){
                            this.showThankModal(answer);
                        }.bind(this));
                        answerOptionsNickname.appendChild(thankButton);
                  };
              }



            answerOptionsHolder.appendChild(answerOptionsTitle);

            if(this.showWrongAnswerFeedbackButton){
                answerOptionsHolder.appendChild(answerOptionsWrongTerm);
            }



            answerOptionsHolder.appendChild(answerOptionsNickname);

                if(parseInt(answer.user_id) === parseInt(this.user_id)){

                    if(localStorage.getItem("grepper_access_token")){
                    var answerOptionsDelete=document.createElement("a");
                        answerOptionsDelete.classList.add("commando_answers_options_delete");
                        answerOptionsDelete.textContent="Delete";
                        answerOptionsDelete.addEventListener('click',function(){
                            this.deleteAnswer(answer.id);
                        }.bind(this));

                          answerOptionsHolder.appendChild(answerOptionsDelete);
                      var answerOptionsEdit=document.createElement("a");
                            answerOptionsEdit.classList.add("commando_answers_options_edit");
                            answerOptionsEdit.textContent="Edit";
                            answerOptionsEdit.addEventListener('click',function(){
                                if(answer.is_advanced){
                                    this.editAdvancedAnswerStart(answer);
                                }else{
                                    this.editAnswerStart(answer);
                                }
                            }.bind(this));

                        answerOptionsHolder.appendChild(answerOptionsEdit);
                    }

                }else{
                  if(!answer.is_promotion){
                        if(localStorage.getItem("grepper_access_token")){
                          var answerOptionsEdit=document.createElement("a");
                                answerOptionsEdit.classList.add("commando_answers_options_edit");
                                answerOptionsEdit.textContent="Suggest Edit";
                                answerOptionsEdit.addEventListener('click',function(){

                                    if(answer.is_advanced){
                                        this.editAdvancedAnswerStart(answer,true);
                                    }else{
                                        this.editAnswerStart(answer,true);
                                    }
                                }.bind(this));

                            answerOptionsHolder.appendChild(answerOptionsEdit);
                        }
                  }
                }


                var answerOptionsShare=document.createElement("a");
                    answerOptionsShare.classList.add("commando_answers_options_edit");
                    answerOptionsShare.textContent="Share";

                    answerOptionsShare.addEventListener('click',function(){
                        this.showShareGrepperSocialShareModal(answer.id);
                    }.bind(this));
                    answerOptionsHolder.appendChild(answerOptionsShare);
                    

            answerOptionsHolder.answerOptionsNickname=answerOptionsNickname;


    return answerOptionsHolder;

}

commando.prototype.displayInlineAd =function() {
      if(localStorage.getItem("hide_youcom_ad")){
          return false;
      }

      var addHolderOutter=document.createElement("a");
          addHolderOutter.classList.add("grepper_ad_holder");
          addHolderOutter.href="https://you.com/pro";

      var addnotify=document.createElement("div");
          addnotify.classList.add("grepper_ad_notify");
          addnotify.textContent="Grepper Ad";
          addHolderOutter.appendChild(addnotify);

      var addClose=document.createElement("div");
          addClose.classList.add("grepper_ad_close");
          addClose.textContent="✕";
          addClose.addEventListener('click',function(event){
            event.stopPropagation(); 
            event.preventDefault();
            addHolderOutter.parentElement.removeChild(addHolderOutter);
            localStorage.setItem("hide_youcom_ad","1");
          }.bind(this));

          addHolderOutter.appendChild(addClose);

      var addHolderText1=document.createElement("div");
          addHolderText1.classList.add("grepper_ad_holder_text_1");
          addHolderText1.textContent="//Get more code written, debugged, and";

      var addHolderText2=document.createElement("div");
          addHolderText2.classList.add("grepper_ad_holder_text_2");
          addHolderText2.textContent=" deployed ";

      var addHolderText3=document.createElement("div");
          addHolderText3.classList.add("grepper_ad_holder_text_3");
          addHolderText3.textContent="with ";

      var addHolderText4=document.createElement("div");
          addHolderText4.classList.add("grepper_ad_holder_text_4");
          addHolderText4.textContent="GPT-4";
          //addHolderText4.href="https://you.com/pro";

      var addHolderText5=document.createElement("div");
          addHolderText5.classList.add("grepper_ad_holder_text_5");
          addHolderText5.textContent=".";
         
          addHolderOutter.appendChild(addHolderText1);
          addHolderOutter.appendChild(addHolderText2);
          addHolderOutter.appendChild(addHolderText3);
          addHolderOutter.appendChild(addHolderText4);
          addHolderOutter.appendChild(addHolderText5);

          this.statsDom.insertBefore(addHolderOutter,this.statsDom.childNodes[this.statsDom.childNodes.length-1]);

}
commando.prototype.displayResultAdvanced =function(answer) {
      var answerHolderOuter=document.createElement("div");
          //answerHolderOuter.classList.add("grepper_answer_enhanced_outer");
          answerHolderOuter.classList.add("commando_code_block_outer");


      var answerOptionsHolder=this.buildAnswerOptionsHolder(answer,answerHolderOuter);
          answerHolderOuter.appendChild(answerOptionsHolder);

      var answerHolder=document.createElement("div");
          answerHolder.classList.add("grepper_answer_enhanced");
          if(answer.is_promotion){
            answerHolder.classList.add("grepper_answer_enhanced_promo");
          }
          answerHolderOuter.appendChild(answerHolder);

            //answerHolderOuter.appendChild(codeResultsPre);

        //note:we kinda duplicate this block in answer_editor (not great)
        var answer_content=JSON.parse(answer.answer);
        let codeResults=[];
        for(var i=0;i<answer_content.tags.length;i++){
            if(answer_content.tags[i].tag=="p"){
                var p=this.htmlToDom(answer_content.tags[i].content);
                    answerHolder.appendChild(p);
            }else if(answer_content.tags[i].tag=="textarea"){

                    var languageGuess="javascript";
                    if(answer_content.tags[i].code_language){
                        languageGuess=answer_content.tags[i].code_language;
                    }
                var codeResultLanguage = document.createElement("div");
                    codeResultLanguage.classList.add("grepper_advanced_code_snippet_language");
                    codeResultLanguage.textContent=this.getLanguageFriendlyName(languageGuess);

                    answerHolder.appendChild(codeResultLanguage);




                var codeResult = document.createElement("code");
                    codeResult.textContent=answer_content.tags[i].content;
                    codeResult.classList.add("commando_code_block");
                    codeResult.classList.add("language-"+languageGuess);

                var codeResultsPre = document.createElement("pre");
                    codeResultsPre.classList.add("language-"+languageGuess);
                    codeResultsPre.classList.add("commando_selectable");
                    codeResultsPre.appendChild(codeResult);
                    answerHolder.appendChild(codeResultsPre);

                    codeResults.push(codeResult);
                   // Prism.highlightAll();
            }
        }

        var commandoVotingHolder=this.getVotingHolder(answer);
       this.addTeamImage(answer,answerHolderOuter);

        answerHolderOuter.appendChild(commandoVotingHolder);


          //// START OF COMMENTS /////
      var showCommentButton = document.createElement("a");
          showCommentButton.classList.add("grepper_show_comment_button");
          showCommentButton.textContent="Comments("+parseInt(answer.t_comments)+")";
      var addCommentButton = document.createElement("a");
          addCommentButton.classList.add("grepper_add_comment_button");
          addCommentButton.textContent="Comment";
          addCommentButton.addEventListener('click',function(){

            if(answer.newCommentHolder){
                answer.newCommentHolder.parentNode.removeChild(answer.newCommentHolder);
                answer.newCommentHolder=false;
                return;
            }
            this.addNewComment(answer,answerHolderOuter);

          }.bind(this));

      var commentButtonHolder = document.createElement("div");
          commentButtonHolder.classList.add("grepper_comments_button_holder");

        var showOrAddButton = (answer.t_comments) ? showCommentButton:addCommentButton;
          answerOptionsHolder.answerOptionsNickname.appendChild(showOrAddButton);
          showCommentButton.addEventListener('click',function(){
              this.getAndShowAnswerComments(answer,answerHolderOuter);
           }.bind(this));
          //// END OF COMMENTS /////


        //source url
          var sourceURLHolder = this.buildSourceURLHolder(answer);
          if(answer.source_url && this.isValidSource(answer.source_url)){
            answerHolderOuter.appendChild(sourceURLHolder);
          }

          if(answer.is_promotion){
            answerHolderOuter.appendChild(sourceURLHolder);
          }


       answer.codeResults=codeResults;
       answer.myDom=answerHolderOuter;

       this.statsDom.insertBefore(answerHolderOuter,this.statsDom.childNodes[this.statsDom.childNodes.length-1]);

     //let textareas =answerHolder.getElementsByClassName('tays_codemirror_textarea_init');
     //for(let i=0;i<textareas.length;i++){
     //     this.highlightCodeAdvancedAnswers(textareas[i]);
     //}
}


//only parse p , and textarea
commando.prototype.highlightCodeAdvancedAnswers =function(results) {
 //   <p tabindex="0">Hello taylor This is just a test on how do go about doing such a thing.</p>
  //  <p tabindex="0">I don't really think that could be wrong no?</p>

}

//and the second results are here
commando.prototype.displayResults2 =function(results) {
     var answerIds=[];
     for(var i=0;i<this.answers.length;i++){
         answerIds.push(this.answers[i].id);
     }

     for(var i=0;i<results.answers.length;i++){
         if(answerIds.indexOf(results.answers[i].id) === -1){
            this.answers.push(results.answers[i]);    
            this.displayResult(results.answers[i]);

         }
     }

     this.setLastChildMargin();

     Prism.highlightAll();
   //if(this.answers.length > 0){
   //      this.setupCopyListener();
   //}

     //this.doneLoadingAnswersDom=true;
     this.setupScrollOverflowDownClick();
}


commando.prototype.setupScrollOverflowDownClickForAnswer =function(answer) {
    if(!answer.myDom){
        return;
    }
    
     //blocker to prevent duplicates
    var hasOverflowDownAlready = answer.myDom.getElementsByClassName("tays_show_more_answer_button_show");
    if(hasOverflowDownAlready.length){
        return;
    }

   let codeDoms= answer.myDom.querySelectorAll("pre code"); 

     for (let i = 0; i < codeDoms.length; i++) {
         let codeDom=codeDoms[i];
             //229 is 11 lines 250 is 12 lines
             //Im going to user 235 to be sure it is > 11 lines
        let hasVerticalScrollbar = codeDom.scrollHeight > 235;
            if(hasVerticalScrollbar){
            let showMoreAnswer = document.createElement("div");
                showMoreAnswer.classList.add("tays_show_more_answer_button_show");
                let codePreDom=  codeDom.parentNode; 
                insertAfter(showMoreAnswer,codePreDom);
                codePreDom.classList.add("grepper_code_expanded_no_bottom_margin");
                showMoreAnswer.addEventListener('click',function(){
                    if(codeDom.style.maxHeight != "none"){
                        showMoreAnswer.classList.add("tays_show_more_answer_button_hide");
                        showMoreAnswer.classList.remove("tays_show_more_answer_button_show");
                        codeDom.style.maxHeight = "none"; 
                    }else{
                        showMoreAnswer.classList.add("tays_show_more_answer_button_show");
                        showMoreAnswer.classList.remove("tays_show_more_answer_button_hide");
                        codeDom.style.maxHeight = "224px"; 
                        
                    }

                }.bind(this));
            }
    }
}

commando.prototype.setupScrollOverflowDownClick =function() {
 for(let i=0;i<this.answers.length;i++){
     this.setupScrollOverflowDownClickForAnswer(this.answers[i]);
 }
}

commando.prototype.setLastChildMargin =function() {

      var allGrepperItems = document.querySelectorAll(".grepperp_writeup_holder,.commando_code_block_outer");

     for(var i=0;i<allGrepperItems.length;i++){
        allGrepperItems[i].classList.remove("grepper_last_normal_answer");
     }
     for (var i = allGrepperItems.length - 1; i >= 0; i--) {
             if(allGrepperItems[i].style.display !="none"){
                allGrepperItems[i].classList.add("grepper_last_normal_answer");
                return;
             }
     }
}

commando.prototype.displayResults3Init =function(answers) {
     let answerIds=[];
     for(let i=0;i<this.answers.length;i++){
         answerIds.push(this.answers[i].id);
     }

     for(let i=0;i<answers.length;i++){
         if(answerIds.indexOf(answers[i].id) === -1){
            answers[i].isExtraAnswer=true;
            this.answers.push(answers[i]);    

        //    this.displayResult(answers[i]);
           if(answers[i].is_advanced){
                this.displayResultAdvanced(answers[i]);
           }else{
                this.displayResult(answers[i]);
           }
            
            this.setupScrollOverflowDownClickForAnswer(answers[i]);
         }
     }

    this.showHideMoreAnswersButton = document.createElement("div");
    this.showHideMoreAnswersButton.setAttribute("id","tays_add_more_answers_button_hide");
    this.showHideMoreAnswersButton.textContent="Hide "+this.moreAnswersTotalCount+" More Grepper Results";

    this.showHideMoreAnswersButton.addEventListener('click',function(){
        this.toggleMoreAnswersHide();
    }.bind(this));

    if(this.searchEngineId ==2){
        var insertAfterElements=this.statsDom.querySelectorAll('.commando_code_block_outer');
            insertAfter(this.showHideMoreAnswersButton,insertAfterElements[insertAfterElements.length-1]);
            this.grepperDomElements.push(this.showHideMoreAnswersButton);
    }else{
        this.statsDom.insertBefore(this.showHideMoreAnswersButton,this.statsDom.childNodes[this.statsDom.childNodes.length-1]);
    }

    this.setLastChildMargin();
    Prism.highlightAll();

  // if(this.answers.length > 0){
  //       this.setupCopyListener();
  // }
}

commando.prototype.showAddAnswerButtonYouCom =function() {
    var addAnswerButton = document.createElement("a");
    var addAnswerButtonHolder = document.createElement("div");

        addAnswerButtonHolder.classList.add("youcom_commando_add_answer_button_holder");
        addAnswerButtonHolder.setAttribute("id","youcom_commando_add_answer_button_holder");

        addAnswerButton.textContent="Add Grepper Answer";
        addAnswerButton.classList.add("commando_add_answer_button");
        addAnswerButton.classList.add("commando_you_button");
        addAnswerButton.setAttribute("id","grepper_add_answer_button");
        addAnswerButtonHolder.appendChild(addAnswerButton);
        this.statsDom.insertBefore(addAnswerButtonHolder,this.statsDom.firstChild);

        this.grepperDomElements.push(addAnswerButtonHolder);
        

        addAnswerButton.addEventListener('click',function(){
            this.displayAnswerBoxDefault();
        }.bind(this));
}

commando.prototype.showAddAnswerButton =function() {
    if(this.searchEngineId==2){
        return;
    }
    var resultStats = document.getElementById("resultStats");
    if(!resultStats){
        resultStats = document.getElementById("result-stats");
    }
    if(!resultStats){
        resultStats = document.getElementById("mBMHK");
    }

    var addAnswerButton = document.createElement("a");
    var addWriteupButton = document.createElement("a");

     //if we use top nave we need to add special style
     var hideWriteupButton=true;
    if(!resultStats){
        resultStats = document.getElementById("appbar");
        if(resultStats){
            hideWriteupButton=true;
            //addAnswerButton.classList.add("grepper_add_answer_button_in_top_nav");
            addAnswerButton.style.display="inline-block";
            addAnswerButton.style.left = "666px";
            addAnswerButton.style.top = "-18px";
            addAnswerButton.style.position="relative";
            //writeup button
          //addAnswerButton.style.display="inline-block";
          //addAnswerButton.style.left = "666px";
          //addAnswerButton.style.top = "-18px";
          //addAnswerButton.style.position="relative";


        }
    }

        addAnswerButton.textContent="« Add Grepper Answer (a)";
        addAnswerButton.classList.add("commando_add_answer_button");
        addAnswerButton.setAttribute("id","grepper_add_answer_button");

        //writuep
        addWriteupButton.textContent="Add Writeup";
        addWriteupButton.classList.add("commando_add_writeup_button");
        addWriteupButton.setAttribute("id","grepper_add_writeup_button");

        addAnswerButton.addEventListener('click',function(){
            this.displayAnswerBoxDefault();
        }.bind(this));

        addWriteupButton.addEventListener('click',function(){
            this.addNewWriteup()
        }.bind(this));

        if(resultStats){
            resultStats.appendChild(addAnswerButton);
            if(!hideWriteupButton){
                resultStats.appendChild(addWriteupButton);
            }
        }
        //after we show answer we do this
        //removing this for now uncomment to add bounnty back in
}




commando.prototype.switchToSimpleEditor = function(){
    if(this.simpleAnswerBoxHolder){
        this.simpleAnswerBoxHolder.style.display="block";
    }
    let advacedAnswerHolderOuter = document.getElementById("grepper_answer_enhanced_outer")

    if(advacedAnswerHolderOuter){
        advacedAnswerHolderOuter.style.display="none";
    }

}

commando.prototype.switchToAdvancedEditor = function(content){
    if(this.simpleAnswerBoxHolder){
        this.simpleAnswerBoxHolder.style.display="none";
    }
    if(!this.gae){
        this.injectScript('codemirror/lib/codemirror.js', 'body',function(){
        this.injectScript('answer_editor.js', 'body',function(){
                this.disableKeyTriggers=true;
                this.gae=new grepperAnswerEditor(this);
                this.gae.displayAdvancedAnswerEditor(false,false,content);
          }.bind(this));
          }.bind(this));
    }else{
        let advacedAnswerHolderOuter = document.getElementById("grepper_answer_enhanced_outer")
        if(advacedAnswerHolderOuter){
            advacedAnswerHolderOuter.style.display="block";
        }

    }
}

commando.prototype.displayAnswerBoxDefault = function(){
 
            if(this.advanced_answer_default){
               this.injectScript('codemirror/lib/codemirror.js', 'body',function(){
                this.injectScript('answer_editor.js', 'body',function(){
                        this.disableKeyTriggers=true;
                        this.gae=new grepperAnswerEditor(this);
                        this.gae.displayAdvancedAnswerEditor(false);
                  }.bind(this));
                  }.bind(this));

            }else{
              this.injectScript('codemirror/lib/codemirror.js', 'body',function(){
                 this.displayAnswerBox();
              }.bind(this));
            }

};

commando.prototype.addNewWriteup =function(){
      makeRequest('GET',this.endpoint+"/check_auth_simple.php").then(function(d){
            var stats = JSON.parse(d);
            if(!stats.success && stats.reason=="Unauthorized"){
                this.showLoginPopup('add_writeup');
            }else{
                window.open(this.web_endpoint+"/app/writeup.php?start_title="+encodeURIComponent(this.search),'_blank');
            }
    }.bind(this));
}


//  commando.prototype.changeEditorBoxLanguage = function(l){
//      this.myTaysCodeMirror.setOption("mode", this.languangeNametoTaysCodeMirrorName(l));
//  }

commando.prototype.getLanguageFriendlyName =function(l){
    var options=getAllLanguages();
    return options[l].name;
 // for(var i=0;i<options.length;i++){
 //     if(l===options[i].lkey){
 //        return options[i].name;
 //     }
 // }
 // return 'whatever';
}

commando.prototype.languageToSelect =function(l){
    this.editorCurrentLanguageSelect  = document.createElement('select');
    this.editorCurrentLanguageSelect.setAttribute("id","languange_guess_display");

    this.editorCurrentLanguageSelect.addEventListener('change',function(){
        var l=this.editorCurrentLanguageSelect.value;
        this.languangeNametoTaysCodeMirrorName(l,function(mimeType){
            this.myTaysCodeMirror.setOption("mode", mimeType);
        }.bind(this));
    }.bind(this));
    
    getLanguageSelectOptions(function(options){
        for (var key in options) {
              var opt = document.createElement('option');
                opt.value = key;
                opt.textContent = options[key];
                if(l===key){
                    opt.setAttribute("selected", "selected");
                }
                this.editorCurrentLanguageSelect.appendChild(opt);
        }
    }.bind(this));
}


commando.prototype.startsWith=function(str,word){
    return str.lastIndexOf(word, 0) === 0;
}

commando.prototype.isValidSource=function(str){
  if(!str){return false;}
  if(!this.startsWith(str,"http://") && !this.startsWith(str,"https://")){
        return false;    
  }
  var res = str.match(/(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)/g);
  return (res !== null);
}

commando.prototype.maxLength=function(str,length){
    return str.length > length ? str.substring(0, length) + "..." : str;
}

commando.prototype.showNeedsPaymentBox=function(subExpiredText){
 var that=this;
 var taysPopup = document.createElement("div");
     taysPopup.classList.add("tays_popup")
     taysPopup.setAttribute("id","grepper-editor");
 var taysPopupInner = document.createElement("div");
     taysPopupInner.classList.add("tays_popup_inner_main_page")

var  taysPopupTextAreaHolder = document.createElement("div");
     taysPopupTextAreaHolder.classList.add("tays_popup_textarea_holder")

 var taysPopupCloseButton = document.createElement("div");
     taysPopupCloseButton.classList.add("tays_popup_close_button")
     taysPopupCloseButton.textContent="X";
     taysPopupCloseButton.addEventListener('click',function(){
         that.closeEditor();
     });
 var taysPopupHeader1 = document.createElement("div");
     taysPopupHeader1.classList.add("tays_popup_header1")
     taysPopupHeader1.textContent="Your Grepper Free Trial is Up!";
var taysPopupHeader2 = document.createElement("div");
     taysPopupHeader2.classList.add("grepper_buy_time_text")
     taysPopupHeader2.textContent=subExpiredText;


var taysPopupHeader3_holder = document.createElement("div");
    taysPopupHeader3_holder.classList.add("grepper_buy_time_button_holder")

 var taysPopupHeader3 = document.createElement("a");
     taysPopupHeader3.classList.add("grepper_activate_full_button")
     taysPopupHeader3.textContent="Activate Grepper Full »";
     taysPopupHeader3.href="https://www.grepper.com/checkout/checkout.php";
     taysPopupHeader3.target="_blank";


    taysPopupTextAreaHolder.appendChild(taysPopupHeader1);
    taysPopupTextAreaHolder.appendChild(taysPopupHeader2);
    taysPopupHeader3_holder.appendChild(taysPopupHeader3);
    taysPopupTextAreaHolder.appendChild(taysPopupHeader3_holder);
    taysPopupInner.appendChild(taysPopupCloseButton);
    taysPopupInner.appendChild(taysPopupTextAreaHolder)
    taysPopup.appendChild(taysPopupInner);
    document.body.appendChild(taysPopup);

}

commando.prototype.closeEditor=function(){
    var editor=  document.getElementById("grepper-editor");
    if(editor && editor.parentNode){
        editor.parentNode.removeChild(editor);
    }
}


//inject another js file from content script
//this will only load a script once
commando.prototype.injectScript = function(file, node ,callback) {
  if(this.loadedCodeMirrorModes.indexOf(file) === -1){
      this.loadedCodeMirrorModes.push(file);
      var message = { "action":"runContentScript", "file":file };
      chrome.runtime.sendMessage(message, function(response) {
          if(response.done) {
             callback(); 
          }
      });
   }else{
       callback();    
   }

}

commando.prototype.loadMyMoreResults=function(others){
  return new Promise(function (resolve, reject) {

   var postData={
        "results":this.resultsURLS,
        "search":this.search,
        "user_id":this.user_id
    };
    makeRequest('POST', this.endpoint+"/get_more_answers.php?others="+others+this.tifgrpr,JSON.stringify(postData)).then(function(r){
      var fullResult = JSON.parse(r);
      var results = fullResult.answers;
      //we just add one answer to current results 
      var answerIds=[];
      for(var i=0;i<this.answers.length;i++){
         answerIds.push(this.answers[i].id);
      }

      for(var i=0;i<this.moreAnswers.length;i++){
         answerIds.push(this.moreAnswers[i].id);
      }
        
     //push up to 2 moreResults onto answers
      for(var i =0;i<results.length;i++){
         if(this.answers.length >= 2 ){break;}
         if(answerIds.indexOf(results[i].id) === -1){
             results[i].isRequestedExtraAnswer=true;
             this.answers.push(results[i]);
             answerIds.push(results[i].id);

                //this.displayResult(results[i]);
              if(results[i].is_advanced){
                    this.displayResultAdvanced(results[i]);
               }else{
                    this.displayResult(results[i]);
               }



         }
      }
      this.setLastChildMargin();
     
     //push the rest onto more answers 
      for(var i =0;i<results.length;i++){
         if(answerIds.indexOf(results[i].id) === -1){
             results[i].isRequestedExtraAnswer=true;
             this.moreAnswers.push(results[i]);
             answerIds.push(results[i].id);
            this.moreAnswersTotalCount+=1;
         }
      }

        Prism.highlightAll();

        this.setupScrollOverflowDownClick();

        if(this.moreAnswersTotalCount > 0){
            this.doShowMoreAnswersButton();
        }
        
        //this.setupFeedBackListeners();//this is for sending feedback on copy, needs blocker

        resolve();
    }.bind(this));
  }.bind(this));

}

commando.prototype.guessCodeLanguage=function(callback){

    var term =this.search;
    var allTerms = getLangaugeSearchTerms();
    var allPossibleTerms= [];

     getLanguageSelectOptions(function(options){
         for(var i =0;i< allTerms.length;i++){
            if((typeof options[allTerms[i].name]) !== 'undefined'){
                allPossibleTerms.push(allTerms[i]);        
            }    
         }

         //now try to find the answer
         for(var i =0;i< allPossibleTerms.length;i++){
             for(var j =0;j< allPossibleTerms[i].terms.length;j++){
                if( (term.toLowerCase().indexOf(allPossibleTerms[i].terms[j]+" ") !== -1) || (term.toLowerCase().indexOf(" "+allPossibleTerms[i].terms[j]) !== -1)) {
                    callback(allPossibleTerms[i].name); return;
                }
             }  
         }

        callback('whatever'); return;
    }.bind(this));
    
}


commando.prototype.addNewComment=function(answer,codeResultsOuter){

            answer.newCommentHolder= document.createElement("div");
            answer.newCommentHolder.classList.add("new_comment_holder");

            var comment = document.createElement("textarea");
                comment.setAttribute("placeholder","Be Helpful! Be Cool!\n\nComments support `inline code`");
                comment.classList.add("grepper_comment_textarea");

            var saveNewCommentButton= document.createElement("button");
                saveNewCommentButton.textContent="Save Comment";
                saveNewCommentButton.addEventListener('click',function(){
                    this.saveComment(comment.value,answer).then(function(newComment){
                        if(parseInt(newComment) === 1){
                            this.getAndShowAnswerComments(answer,codeResultsOuter,true);
                        }else{
                            //alert("You need to log in to your Grepper account to add a comment.");
                            this.showLoginPopup('add_comment');
                        }
                    }.bind(this)).catch(function() {
                    //console.log('error');
                    });
                }.bind(this));


            var newCommentSaveButtonHolder= document.createElement("div");
                newCommentSaveButtonHolder.classList.add("new_comment_save_button_holder");
                newCommentSaveButtonHolder.appendChild(saveNewCommentButton);



                answer.newCommentHolder.appendChild(comment);
                answer.newCommentHolder.appendChild(newCommentSaveButtonHolder);
                

                codeResultsOuter.appendChild(answer.newCommentHolder);
                comment.focus();

}

commando.prototype.saveComment=function(commentText,answer){
    var postData={
        "comment":commentText,
        "answer_id":answer.id,
        "user_id":this.user_id
    };

    if(commentText.length < 12){
        alert("That's a little too short, comments must be at least 12 characters.");
        return new Promise(function(resolve, reject) { reject("to short"); });
    }

    if(commentText.length > 800){
        alert("That's a little too long, comments must be limited to 800 characters.");
        return new Promise(function(resolve, reject) { reject("to long"); });
    }

    return makeRequest('POST', this.endpoint+"/save_comment.php",JSON.stringify(postData));

}

commando.prototype.displayComment=function(comment,commentHolder,codeResultsOuter,answer){

      var commentDomOuter = document.createElement("div");
          commentDomOuter.classList.add("grepper_comment");
          commentHolder.appendChild(commentDomOuter);


         var commandoVotingHolder= document.createElement("div");
             commandoVotingHolder.classList.add("grepper_comment_voting_holder");

              commentDomOuter.appendChild(commandoVotingHolder);

          var voteNumber= document.createElement("div");
              voteNumber.classList.add("commando-voting-number");
              voteNumber.classList.add("comment-commando-voting-number");
              voteNumber.textContent=(comment.t_upvotes-comment.t_downvotes);
              commandoVotingHolder.appendChild(voteNumber);


          var upvote= document.createElement("div");
              upvote.classList.add("arrow-up");
              upvote.classList.add("comment-arrow-up");
              upvote.setAttribute("comment_id",comment.id);
              upvote.addEventListener('click', this.doCommentUpvote.bind(this,event,comment));

              if(comment.i_upvoted == 1){
                upvote.classList.add("comment_commando_voted");
               }


              commandoVotingHolder.appendChild(upvote);

          var downvote= document.createElement("div");
              downvote.classList.add("arrow-down");
              downvote.classList.add("comment-arrow-down");
              downvote.setAttribute("comment_id",comment.id);
              downvote.addEventListener('click', this.doCommentDownvote.bind(this,event,comment));

              if(comment.i_downvoted == 1){
                downvote.classList.add("comment_commando_voted");
               }
              commandoVotingHolder.appendChild(downvote);


  var commentDom = document.createElement("span");
      commentDom.classList.add("grepper_comment_text");

  var commentTextSplit=comment.comment.split('`');//.map((el, i) => i % 2 ? '`' + el + '`' : el)
  for(var i=0;i<commentTextSplit.length;i++){
      if(i%2){
            var newElement= document.createElement("code");
      }else{
            var newElement= document.createElement("span");
      }
          newElement.textContent=commentTextSplit[i];
          commentDom.appendChild(newElement);
  }


      commentDomOuter.appendChild(commentDom);

   var userProfileLink= document.createElement("a");
       userProfileLink.target="_blank";
       userProfileLink.href="https://www.grepper.com/profile/"+comment.profile_slug;
       if(this.user_id == comment.user_id){
         userProfileLink.textContent = " Me ("+jsUcfirst(comment.fun_name)+")";
       }else{
         userProfileLink.textContent = " "+jsUcfirst(comment.fun_name);
       }

       commentDomOuter.appendChild(userProfileLink);

        var t = comment.created_at.split(/[- :]/);
        var d = new Date(Date.UTC(t[0], t[1]-1, t[2], t[3], t[4], t[5]));

        var currentTime=new Date();

        //less than 30 seconds add orange background
        if((currentTime.getTime()-d.getTime()) < (1000*1*2)){
          commentDomOuter.classList.add("grepper_comment_recently_created");
        }


        var formattedDate=dateToNiceDayString(d);
        var dateOnSpan= document.createElement("i");
            dateOnSpan.textContent = " "+formattedDate+" ";
            dateOnSpan.classList.add("grepper_comment_date");


           commentDomOuter.appendChild(dateOnSpan);

            if(this.user_id == comment.user_id){
            var commentDeleteButton= document.createElement("a");
                commentDeleteButton.classList.add("comment_delete_button");
                commentDeleteButton.textContent=" Delete";

                commentDeleteButton.addEventListener('click',function(){
                        var postData={
                        "comment_id":comment.id,
                        };
                     makeRequest('POST', this.endpoint+"/delete_comment.php",JSON.stringify(postData)).then(function(newComment){
                        if(parseInt(newComment) === 1){
                            this.getAndShowAnswerComments(answer,codeResultsOuter,true);
                        }else{
                            //alert("You need to log in to your Grepper account to perform this action.");
                            this.showLoginPopup('perform_action');
                        }
                     }.bind(this));

                }.bind(this));

                commentDomOuter.appendChild(commentDeleteButton);
            }
       


}

commando.prototype.getAndShowAnswerComments=function(answer,codeResultsOuter,refresh){
            refresh = (typeof refresh !== 'undefined') ?  refresh : false; 

             if(refresh){
                    if(answer.newCommentHolder){
                        answer.newCommentHolder.parentNode.removeChild(answer.newCommentHolder);
                        answer.newCommentHolder=false;
                    }
             }

            if(answer.commentHolder){
                answer.commentHolder.parentNode.removeChild(answer.commentHolder);
                answer.commentHolder=false;

                if(answer.newCommentHolder){
                    answer.newCommentHolder.parentNode.removeChild(answer.newCommentHolder);
                    answer.newCommentHolder=false;
                }
                if(!refresh){
                    return;
                }
            }



        makeRequest('GET', this.endpoint+"/get_answers_comments.php?aid="+answer.id+"&u="+this.user_id,{},true).then(function(commentsData){
            var commentsD=JSON.parse(commentsData);
            var comments=commentsD.comments;

              answer.commentHolder = document.createElement("div");
              answer.commentHolder.classList.add("grepper_comments_holder");
              codeResultsOuter.appendChild(answer.commentHolder);

            //lets show the comments
            for(let b=0;b<comments.length;b++){
                this.displayComment(comments[b],answer.commentHolder,codeResultsOuter,answer);

            }
          //Add another comment button
          var addAnotherCommentButton = document.createElement("a");
              addAnotherCommentButton.classList.add("grepper_add_another_comment_button");
              addAnotherCommentButton.textContent="Add New Comment";
              addAnotherCommentButton.addEventListener('click',function(el){
                  el.target.style.display="none";
                  this.addNewComment(answer,codeResultsOuter);

              }.bind(this));

              answer.commentHolder.appendChild(addAnotherCommentButton);

        }.bind(this));
}

commando.prototype.getRandomTitle=function(){
var titles=[
    'Ahhh, thanks for the answer!',
    'Nice Answer!',
    'Good Work!',
    'O,thanks for the answer!',
    'Your coding like a boss!',
    'Thanks for the answer!',
    'Thank for giving back!',
    'We are forever grateful!',
    'Hard work pays off!',
    'Much appreciated!',
    'Wow, nice answer!',
    'Thanks, says your future self!',
    'How are you so awesome!',
    'Muchas gracias!',
    'Heck Yea!',
    'Woot Woot!',
    'Shazaaam!',
    'Pogger!'
];

return titles[Math.floor(Math.random() * titles.length)];

}

commando.prototype.showGrepperCoinPopup=function(grepper_gold,grepper_gold_total){

      var goldPopup = document.createElement("div");
          goldPopup.classList.add("grepper_gold_popup");
          goldPopup.setAttribute("id","grepper_gold_popup");

      var title=this.getRandomTitle();


      var goldPopupIMGHolder = document.createElement("div");
          goldPopupIMGHolder.classList.add("grepper_gold_popup_img_holder");
        //we will first add the fives
        //for(var i=10;i<=grepper_gold;i+=10){
      var goldPopupIMG = document.createElement("div");
          goldPopupIMG.classList.add("grepper_gold_popup_img_10");
 
      var goldPopupIMGA = document.createElement("img");
          goldPopupIMGA.src=chrome.runtime.getURL("img/grepper_coin_50.png")
          goldPopupIMG.appendChild(goldPopupIMGA);


          //goldPopupIMG.style.right=((i-10)*1.5)+"px";

          goldPopupIMGHolder.appendChild(goldPopupIMG);
        //}
    

          goldPopup.appendChild(goldPopupIMGHolder);

      var goldPopupX = document.createElement("div");
          goldPopupX.classList.add("grepper_gold_popup_x");
          goldPopupX.textContent="×";
          goldPopupX.addEventListener("click",function(){
            goldPopup.parentNode.removeChild(goldPopup);
          })


      var goldPopupTitle = document.createElement("div");
          goldPopupTitle.classList.add("grepper_gold_popup_title");
          goldPopupTitle.textContent="Thanks for Sharing!";

        var goldPopupText1 = document.createElement("div");
          goldPopupText1.classList.add("grepper_gold_popup_text1_grepcc");
          goldPopupText1.textContent= "You just earned "+grepper_gold+" Grepper Contributor Coin!";


          var goldPopupText3 = document.createElement("a");
          goldPopupText3.classList.add("grepper_gold_popup_text3");
          goldPopupText3.href="https://www.grepper.com/app/my_grepper_contributor_coin.php";
          goldPopupText3.setAttribute("target","_blank");
          goldPopupText3.textContent= "Learn more about Grepper Contributor Coin";

          goldPopup.appendChild(goldPopupX);
          goldPopup.appendChild(goldPopupTitle);
          goldPopup.appendChild(goldPopupText1);
          goldPopup.appendChild(goldPopupText3);

          if(document && document.body){
              document.body.appendChild(goldPopup);
          }

          //https://mixkit.co/free-sound-effects/coin/
          var myAudio = new Audio(chrome.runtime.getURL("media/grepper_gold_unlock2.wav"));
               myAudio.play();


        //if this has pry happended a couple times we auto hide
      //if(grepper_gold_total > 30){
          goldPopup.classList.add("grepper_jump_out_long");
      //}
}
commando.prototype.showGrepperProRequired=function(msg){

         var taysPopup = document.createElement("div");
             taysPopup.classList.add("tays_popup")
             taysPopup.classList.add("no_pointer_events")
             taysPopup.setAttribute("id","grepper-editor");


         var taysPopupInner = document.createElement("div");
             taysPopupInner.classList.add("tays_popup_inner_main_page")
             taysPopup.appendChild(taysPopupInner);

         let taysPopupCloseButton = document.createElement("div");
             taysPopupCloseButton.classList.add("tays_popup_close_button")
             taysPopupCloseButton.textContent="×";
             taysPopupInner.appendChild(taysPopupCloseButton);

             taysPopup.addEventListener('click',function(el){
                 if(el.target == taysPopup){
                    this.closeEditor();
                 }
             }.bind(this));

             taysPopupCloseButton.addEventListener('click',function(){
                 this.closeEditor();
             }.bind(this));




        var taysPopupShareInner=document.createElement("div");
            taysPopupShareInner.classList.add("tays_popup_share_inner");

        var grepperLogoImg=document.createElement("img");
            grepperLogoImg.classList.add("tays_share_grepper_logo");
            grepperLogoImg.src=chrome.runtime.getURL("img/icon128_hand.png");
            taysPopupShareInner.appendChild(grepperLogoImg)

        var tpsShareh1=document.createElement("div");
            tpsShareh1.classList.add("tays_grepper_pro_text")
            tpsShareh1.textContent=msg;
            taysPopupShareInner.appendChild(tpsShareh1);

            var learnMore=document.createElement("a");
                learnMore.textContent= "Learn More About Grepper Professional";
                learnMore.href="https://www.grepper.com/subscriptions.php";
                learnMore.target="_blank";
                taysPopupShareInner.appendChild(learnMore);

            taysPopupInner.appendChild(taysPopupShareInner);



        let answerTermPopupBottom  = document.createElement("div");
            answerTermPopupBottom.classList.add("answer_term_popup_bottom")
            taysPopupInner.appendChild(answerTermPopupBottom);

    let answerTermPopupBottomButton  = document.createElement("button");
        answerTermPopupBottomButton.classList.add("answer_term_popup_bottom_button")
        answerTermPopupBottomButton.textContent="Close";
        answerTermPopupBottomButton.addEventListener("click",function(){
         this.closeEditor();
        }.bind(this));
        answerTermPopupBottom.appendChild(answerTermPopupBottomButton);




        var removeMe = document.getElementById("grepper-editor");
        if(removeMe){
            removeMe.parentNode.removeChild(removeMe);
        }



        document.body.appendChild(taysPopup);
}


commando.prototype.showGrepperGoldPopup=function(grepper_gold,grepper_gold_total){

      var goldPopup = document.createElement("div");
          goldPopup.classList.add("grepper_gold_popup");
          goldPopup.setAttribute("id","grepper_gold_popup");

      var title=this.getRandomTitle();


      var goldPopupIMGHolder = document.createElement("div");
          goldPopupIMGHolder.classList.add("grepper_gold_popup_img_holder");
        //we will first add the fives
        for(var i=10;i<=grepper_gold;i+=10){
      var goldPopupIMG = document.createElement("div");
          goldPopupIMG.classList.add("grepper_gold_popup_img_10");
 
      var goldPopupIMGA = document.createElement("img");
          goldPopupIMGA.src=chrome.runtime.getURL("img/grepper_coin_10.png")
          goldPopupIMG.appendChild(goldPopupIMGA);


          //goldPopupIMG.style.right=((i-10)*1.5)+"px";

          goldPopupIMGHolder.appendChild(goldPopupIMG);
        }
        i-=10;
        var remander = grepper_gold-i;
        for(var t=1;t<=remander;t++){

       var goldPopupIMG = document.createElement("div");
           goldPopupIMG.classList.add("grepper_gold_popup_img_1");
 
      var goldPopupIMGA = document.createElement("img");
          goldPopupIMGA.src=chrome.runtime.getURL("img/grepper_coin_10.png")
          goldPopupIMG.appendChild(goldPopupIMGA);

          //goldPopupIMG.style.right=(((i-10)*1.5)+((t*10)*1.5))+"px";
          goldPopupIMGHolder.appendChild(goldPopupIMG);
        }

          goldPopup.appendChild(goldPopupIMGHolder);

      var goldPopupX = document.createElement("div");
          goldPopupX.classList.add("grepper_gold_popup_x");
          goldPopupX.textContent="×";
          goldPopupX.addEventListener("click",function(){
            goldPopup.parentNode.removeChild(goldPopup);
          })


      var goldPopupTitle = document.createElement("div");
          goldPopupTitle.classList.add("grepper_gold_popup_title");
          goldPopupTitle.textContent=title

        var goldPopupText1 = document.createElement("div");
          goldPopupText1.classList.add("grepper_gold_popup_text1");
          goldPopupText1.textContent= "You just earned "+grepper_gold+" Grepper Gold for putting in that answer.";


        var goldPopupText2 = document.createElement("a");
          goldPopupText2.classList.add("grepper_gold_popup_text2");
          goldPopupText2.textContent= "You're now up to "+grepper_gold_total+" Grepper Gold.";
          goldPopupText2.href="https://www.grepper.com/app/my_grepper_gold.php";
          goldPopupText2.setAttribute("target","_blank");

        var goldPopupText3 = document.createElement("a");
          goldPopupText3.classList.add("grepper_gold_popup_text3");
          goldPopupText3.href="https://www.grepper.com/app/docs.php#grepper_gold";
          goldPopupText3.setAttribute("target","_blank");
          goldPopupText3.textContent= "Learn more about Grepper Gold here";

          goldPopup.appendChild(goldPopupX);
          goldPopup.appendChild(goldPopupTitle);
          goldPopup.appendChild(goldPopupText1);
          goldPopup.appendChild(goldPopupText2);
          goldPopup.appendChild(goldPopupText3);

          if(document && document.body){
              document.body.appendChild(goldPopup);
          }

          //https://mixkit.co/free-sound-effects/coin/
          var myAudio = new Audio(chrome.runtime.getURL("media/grepper_gold_unlock2.wav"));
               myAudio.play();


        //if this has pry happended a couple times we auto hide
        if(grepper_gold_total > 30){
            goldPopup.classList.add("grepper_jump_out");
        }
}

commando.prototype.addUserCodeLanguage=function(langToAddKey){
    chrome.storage.sync.get(['grepper_user_langs'], function(all_items) {
         if(!all_items.grepper_user_langs){
            var items=getAllLanguages();
        }else{
            var items=all_items.grepper_user_langs;
        }

        for (var key in items) {
            if(key==langToAddKey){
                items[key].enabled=1;
            }
        }
        chrome.storage.sync.set({grepper_user_langs:items }, function() {});
    });
}

commando.prototype.showShareGrepperSocialShareModal=function(answer_id,i_just_added){

    i_just_added = (typeof i_just_added !== 'undefined') ?  i_just_added : false;

    makeRequest('GET',this.endpoint+"/get_answer_share_data.php?answer_id="+answer_id).then(function(data){
    let answerData=JSON.parse(data);

 var taysPopup = document.createElement("div");
     taysPopup.classList.add("tays_popup")
     taysPopup.classList.add("tays_popup_close_on_click")
     taysPopup.setAttribute("id","grepper-editor");

 var taysPopupInner = document.createElement("div");
     taysPopupInner.classList.add("tays_popup_inner_main_page");
     taysPopupInner.classList.add("tays_popup_inner_social_share");
     taysPopup.appendChild(taysPopupInner);

 let taysPopupCloseButton = document.createElement("div");
     taysPopupCloseButton.classList.add("tays_popup_close_button")
     taysPopupCloseButton.textContent="×";
     taysPopupInner.appendChild(taysPopupCloseButton);

     taysPopup.addEventListener('click',function(el){
         if(el.target == taysPopup){
            this.closeEditor();
         }
     }.bind(this));

     taysPopupCloseButton.addEventListener('click',function(){
         this.closeEditor();
     }.bind(this));


    var taysPopupShareInner=document.createElement("div");
        taysPopupShareInner.classList.add("tays_popup_share_inner");
    var grepperLogoImg=document.createElement("img");
        grepperLogoImg.classList.add("tays_share_grepper_logo");
        grepperLogoImg.src=chrome.runtime.getURL("img/icon128_hand.png");
        //taysPopupShareInner.appendChild(grepperLogoImg)


//  var tpsShareh1=document.createElement("div");
//      tpsShareh1.classList.add("tays_share_h1")
//      tpsShareh1.textContent="Nice! You public answer link is below, show your friends and colleagues your coding skills by sharing your answer."
//      taysPopupShareInner.appendChild(tpsShareh1);

    var tpsSharehIframeHolder=document.createElement("div");
        tpsSharehIframeHolder.classList.add("grepper_twitter_card_iframe_holder");
        taysPopupShareInner.appendChild(tpsSharehIframeHolder);

    var tpsSharehIframe=document.createElement("iframe");
        tpsSharehIframe.src="https://www.grepper.com/answer_card.php?id="+answer_id;
        tpsSharehIframe.classList.add("grepper_twitter_card_iframe");
        tpsSharehIframe.setAttribute("scrolling","no");
        tpsSharehIframeHolder.appendChild(tpsSharehIframe);


    var tpsShareTHolder=document.createElement("div");
        tpsShareTHolder.classList.add("tays_share_url_twitter_holder");
        taysPopupShareInner.appendChild(tpsShareTHolder);

    var tpsShareText=document.createElement("div");
        tpsShareText.classList.add("tays_share_url_twitter_text");
        tpsShareText.textContent="Link To Answer";
        tpsShareTHolder.appendChild(tpsShareText);

    let tpsShareT=document.createElement("input");
        tpsShareT.classList.add("tays_share_url_twitter")
        tpsShareT.setAttribute("type","text");
        tpsShareT.value=answerData.share_url;
        tpsShareTHolder.appendChild(tpsShareT);

    let tpsShareTCopy=document.createElement("a");
        tpsShareTCopy.textContent="Copy Link";
        tpsShareTCopy.addEventListener("click",function(){
            navigator.clipboard.writeText(tpsShareT.value);
            tpsShareTCopy.textContent="Copied";
             setTimeout(function(){
                tpsShareTCopy.textContent="Copy Link";
             }, 1000);
        });
        tpsShareTHolder.appendChild(tpsShareTCopy);


    var tpsSharebh=document.createElement("div");
        tpsSharebh.classList.add("tays_share_button_holder")
        taysPopupShareInner.appendChild(tpsSharebh);

    var shareTexts=[
            encodeURIComponent("ChatGPT's got nothing on the Grepper Community!"),
            encodeURIComponent("Coding away today and I just ran into this super helpful Grepper answer!")
        ];
        var shareText=shareTexts[Math.floor(Math.random() * shareTexts.length)];

        if(i_just_added){
            shareText=encodeURIComponent("Improving my dev skills today, I just added this Grepper Answer.");
        }

    var twitterShare=document.createElement("a");
        twitterShare.classList.add("grepper_twitter_share_button");
        twitterShare.href="https://twitter.com/intent/tweet?text="+shareText+"&url="+encodeURIComponent(tpsShareT.value);
        twitterShare.setAttribute("target","_blank");
        twitterShare.textContent="Share On Twitter";
        tpsSharebh.appendChild(twitterShare);
 
    var linkedInShare=document.createElement("a");
        linkedInShare.classList.add("grepper_linkedin_share_button");
        //&summary={articleSummary}&source={articleSource}
        //linkedInShare.href="https://www.linkedin.com/shareArticle?mini=true&title="+shareText+"&url="+encodeURIComponent(tpsShareT.value)+"&source="+encodeURIComponent("https://www.grepper.com")+"&summary="+shareText;

        linkedInShare.addEventListener('click',function(){
            var linkedin_url="https://www.linkedin.com/sharing/share-offsite/?url="+encodeURIComponent(tpsShareT.value);
            this.popupWindow(linkedin_url,600,760);
           this.closeEditor();
        }.bind(this));

        //linkedInShare.setAttribute("target","_blank");
        linkedInShare.textContent="Share On LinkedIn";
        tpsSharebh.appendChild(linkedInShare);



        taysPopupInner.appendChild(taysPopupShareInner);


    let answerTermPopupBottom  = document.createElement("div");
        answerTermPopupBottom.classList.add("answer_term_popup_bottom")
        //taysPopupInner.appendChild(answerTermPopupBottom);

    var removeMe = document.getElementById("grepper-editor");
    if(removeMe){
	    removeMe.parentNode.removeChild(removeMe);
    }
    document.body.appendChild(taysPopup);
    }.bind(this));

}

commando.prototype.showShareGrepperModal=function(answer){
    this.showLoginIfNot();
    this.currentEditingAnswer=answer;

 var taysPopup = document.createElement("div");
     taysPopup.classList.add("tays_popup")
     taysPopup.setAttribute("id","grepper-editor");

 var taysPopupInner = document.createElement("div");
     taysPopupInner.classList.add("tays_popup_inner_main_page")
     taysPopup.appendChild(taysPopupInner);


    var taysPopupShareInner=document.createElement("div");
        taysPopupShareInner.classList.add("tays_popup_share_inner");
    var grepperLogoImg=document.createElement("img");
        grepperLogoImg.classList.add("tays_share_grepper_logo");
        grepperLogoImg.src=chrome.runtime.getURL("img/icon128_hand.png");
        taysPopupShareInner.appendChild(grepperLogoImg)



    var tpsShareh1=document.createElement("div");
        tpsShareh1.classList.add("tays_share_h1")
        tpsShareh1.textContent="If you find Grepper helpful, can you please share it with a friend or colleague?"
        taysPopupShareInner.appendChild(tpsShareh1);

    var tpsShareT=document.createElement("textarea");
        tpsShareT.classList.add("tays_share_url")
        tpsShareT.value="https://www.grepper.com";
        taysPopupShareInner.appendChild(tpsShareT);


    var tpsShareh2=document.createElement("div");
        tpsShareh2.classList.add("tays_share_h2")
        tpsShareh2.value="The more Devs that use Grepper the better for everyone!";
        taysPopupShareInner.appendChild(tpsShareh2);

    var tpsSharebh=document.createElement("div");
        tpsSharebh.classList.add("tays_share_button_holder")
        taysPopupShareInner.appendChild(tpsSharebh);


    var tpsShareb3=document.createElement("button");
        tpsShareb3.classList.add("grp_grepper_button1")
        tpsShareb3.textContent= "No Way José";
        tpsSharebh.appendChild(tpsShareb3);
        tpsShareb3.addEventListener("click",function(){
            makeRequest('POST', this.endpoint+"/feedback.php?vote=15&u="+this.user_id);
           this.closeEditor();
          }.bind(this));


    var tpsShareb2=document.createElement("button");
        tpsShareb2.classList.add("grp_grepper_button1")
        tpsShareb2.textContent= "Can't Now, Remind Me Later!";
        tpsSharebh.appendChild(tpsShareb2);
        tpsShareb2.addEventListener("click",function(){
            makeRequest('POST', this.endpoint+"/feedback.php?vote=14&u="+this.user_id);
           this.closeEditor();
          }.bind(this));

    var tpsShareb1=document.createElement("button");
        tpsShareb1.classList.add("grp_grepper_button1")
        tpsShareb1.textContent= "Ok, I Shared it!";
        tpsSharebh.appendChild(tpsShareb1);

        tpsShareb1.addEventListener("click",function(){
            this.showGrepperCoinPopup(100,1);
            makeRequest('POST', this.endpoint+"/feedback.php?vote=13&u="+this.user_id);
           this.closeEditor();
          }.bind(this));


        taysPopupInner.appendChild(taysPopupShareInner);


    let answerTermPopupBottom  = document.createElement("div");
        answerTermPopupBottom.classList.add("answer_term_popup_bottom")
        //taysPopupInner.appendChild(answerTermPopupBottom);


    var removeMe = document.getElementById("grepper-editor");
    if(removeMe){
	    removeMe.parentNode.removeChild(removeMe);
    }
    document.body.appendChild(taysPopup);
}



commando.prototype.showThankModal=function(answer){
 let taysPopup = document.createElement("div");
     taysPopup.classList.add("tays_popup")
     taysPopup.classList.add("tays_popup_close_on_click")
     taysPopup.setAttribute("id","grepper-editor");

 let taysPopupInner = document.createElement("div");
     taysPopupInner.classList.add("tays_popup_inner_main_page")
     taysPopup.appendChild(taysPopupInner);

 let taysPopupCloseButton = document.createElement("div");
     taysPopupCloseButton.classList.add("tays_popup_close_button")
     taysPopupCloseButton.textContent="×";
     taysPopupInner.appendChild(taysPopupCloseButton);


     taysPopup.addEventListener('click',function(el){
         if(el.target == taysPopup){
            this.closeEditor();
         }
     }.bind(this));

     taysPopupCloseButton.addEventListener('click',function(){
         this.closeEditor();
     }.bind(this));

 var taysPopupHeader1 = document.createElement("div");
     taysPopupHeader1.classList.add("tays_popup_header1")
     taysPopupHeader1.textContent="Thank "+ (answer.fun_name);
     taysPopupInner.appendChild(taysPopupHeader1);

 var taysPopupInnerContent = document.createElement("div");
     taysPopupInnerContent.classList.add("tays_popup_inner_content_plugin")
     taysPopupInner.appendChild(taysPopupInnerContent);

 var taysPopupInnerBadgeHolder = document.createElement("div");
     taysPopupInnerBadgeHolder.classList.add("tays_popup_inner_badge_holder")


    
    //load fa-css
    var faCss=document.createElement("link")
        faCss.setAttribute("rel","stylesheet")
        faCss.setAttribute("type","text/css");
        faCss.href=chrome.runtime.getURL("fa_subset/css/all.css");
        taysPopup.appendChild(faCss);


     //put inner stuff here
    makeRequest('GET',this.endpoint+"/get_thanks_modal.php?thank_user="+answer.user_id).then(function(data){
      let thank_user_data=JSON.parse(data);
      if(thank_user_data.success==false && thank_user_data.reason=="Unauthorized"){
            this.showLoginPopup('perform_action');
            return false;
      }

      let awards=thank_user_data.awards;

        let clearBoth = document.createElement("div");
            clearBoth.classList.add("grp_clear_both");

        let leftSideStuff = document.createElement("div");
            leftSideStuff.classList.add("grp_thanks_modal_left_side");
 
        let rightSideStuff = document.createElement("div");
            rightSideStuff.classList.add("grp_thanks_modal_right_side");
        if(thank_user_data.how_to_help){
            let howToThankHeader = document.createElement("div");
                howToThankHeader.classList.add("grp_thanks_how_to_thank_header");
                howToThankHeader.textContent= "Here is how "+answer.fun_name+" says you can thank them:";
                rightSideStuff.appendChild(howToThankHeader);

            let howToThank = document.createElement("div");
                howToThank.classList.add("grp_thanks_how_to_thank");
                howToThank.textContent=thank_user_data.how_to_help;
                rightSideStuff.appendChild(howToThank);
        }
        if(thank_user_data.enable_awards){
            let howToThankHeader2 = document.createElement("div");
                howToThankHeader2.classList.add("grp_thanks_how_to_thank_header2");


            let howToThankHeader2Text=(thank_user_data.how_to_help) ? "Or say  " : "Say ";
                howToThankHeader2.textContent= howToThankHeader2Text+" thanks with a superlative nomination!";
                rightSideStuff.appendChild(howToThankHeader2);
            let superHelpButton=document.createElement("a");
                superHelpButton.classList.add("grp_super_help_button");
                superHelpButton.target="_blank";
                superHelpButton.textContent="?";
                superHelpButton.href="https://www.grepper.com/app/docs.php#grepper_superlatives";
                howToThankHeader2.appendChild(superHelpButton);
        }


        let profilePicA=document.createElement("a");
            profilePicA.href="https://www.grepper.com/profile/"+answer.profile_slug;
            profilePicA.target="_blank";
        let profilePic=document.createElement("img");
            if(thank_user_data.profile_url){
                profilePic.src=this.web_endpoint+"/profile_images/"+thank_user_data.profile_url;
            }else{
                profilePic.src=this.web_endpoint+"/app/img/default_profile.png";
            }
            profilePic.classList.add("grp_thanks_profile_image");

            profilePicA.appendChild(profilePic);
            leftSideStuff.appendChild(profilePicA);

        //real name
        if(thank_user_data.real_name){

        let userRealName = document.createElement("div");
            userRealName.classList.add("grp_thanks_modal_real_name");


        let userRealNameI = document.createElement("i");
            userRealNameI.classList.add("grepper_plugin_fa");
            userRealNameI.classList.add("fa-smile");
            userRealName.textContent=thank_user_data.real_name;
            userRealName.insertBefore(userRealNameI, userRealName.firstChild);
            leftSideStuff.appendChild(userRealName);
        }

        if(thank_user_data.website_url){
        let userWebUrl = document.createElement("a");
            userWebUrl.classList.add("grp_thanks_modal_website_url");
            userWebUrl.href=thank_user_data.website_url;
            userWebUrl.textContent=userWebUrl.hostname;
            userWebUrl.target="_blank";

        let userWebUrlI = document.createElement("i");
            userWebUrlI.classList.add("grepper_plugin_fa");
            userWebUrlI.classList.add("fa-link");
            userWebUrl.insertBefore(userWebUrlI, userWebUrl.firstChild);

            leftSideStuff.appendChild(userWebUrl);
        }

      if(thank_user_data.twitter_name){
        let userTwitterName = document.createElement("a");
            userTwitterName.classList.add("grp_thanks_modal_twitter_name");
            userTwitterName.textContent="@"+thank_user_data.twitter_name;
            userTwitterName.target="_blank";
            userTwitterName.href="https://twitter.com/"+(thank_user_data.twitter_name);


        let userTwitterNameI = document.createElement("i");
            userTwitterNameI.classList.add("grepper_plugin_fab");
            userTwitterNameI.classList.add("fa-twitter");
            userTwitterName.insertBefore(userTwitterNameI, userTwitterName.firstChild);
            leftSideStuff.appendChild(userTwitterName);
        }

        let followButton=document.createElement("div");
            followButton.classList.add("grp_grepper_button1");
            followButton.classList.add("grp_thank_follow_button");
            if(thank_user_data.is_following){
                followButton.setAttribute("is_following",1);
                followButton.textContent="Unfollow";
            }else{
                followButton.setAttribute("is_following",0);
                followButton.textContent="Follow";
            }

            followButton.addEventListener("click",function(){
                let follow = (followButton.getAttribute("is_following") == 1) ? 0 : 1;
                makeRequest('GET',this.endpoint+"/follow.php?follow_user_id="+answer.user_id+"&follow="+follow).then(function(d){
                    if(follow){
                        followButton.setAttribute("is_following",1);
                        followButton.textContent="Unfollow";
                    }else{
                        followButton.setAttribute("is_following",0);
                        followButton.textContent="Follow";
                    }
                }.bind(this));

            }.bind(this));

            leftSideStuff.appendChild(followButton);

           

            rightSideStuff.appendChild(taysPopupInnerBadgeHolder);
            taysPopupInnerContent.appendChild(leftSideStuff);
            taysPopupInnerContent.appendChild(rightSideStuff);
            taysPopupInnerContent.appendChild(clearBoth);


        if(thank_user_data.enable_awards){
        for (let i = 0; i < awards.length; i++) {

        let funBadge = document.createElement("div");
            funBadge.classList.add('gp_fun_badge');
            funBadge.classList.add(awards[i].color);
            if((i+1)%5==0){
                funBadge.style.marginRight="0px";
            }
            if(awards[i].has_voted){
                funBadge.classList.add("has_voted");
            }
            
            funBadge.addEventListener("click",function(){
                let has_voted=funBadge.classList.contains("has_voted");
                let formData = new FormData();
                    formData.append('user_id', answer.user_id);
                    formData.append('award_id', awards[i].id);
                    formData.append('award', (has_voted)?0:1);
                    makeRequest('POST',this.endpoint+"/nominate_super.php",formData).then(function(d){
                        if(has_voted){
                            funBadge.classList.remove("has_voted");
                        }else{
                            funBadge.classList.add("has_voted");
                        }
                    });
            }.bind(this));


        var funBadgeCircle = document.createElement("div");
            funBadgeCircle.classList.add('gpf_circle');
            funBadge.appendChild(funBadgeCircle); 

            //todo:get fa only the needed stuff
        var funBadgeFA = document.createElement("i");
            funBadgeFA.classList.add('grepper_plugin_fa');
            funBadgeFA.classList.add(awards[i].fa_icon);
            funBadgeCircle.appendChild(funBadgeFA); 

        var funBadgeRibbon = document.createElement("div");
            funBadgeRibbon.classList.add('gpf_ribbon');
            funBadgeRibbon.textContent=awards[i].name.replace("<br/>","");
            funBadge.appendChild(funBadgeRibbon);
            taysPopupInnerBadgeHolder.appendChild(funBadge);

            var hasVotedIcon = document.createElement("i");
                hasVotedIcon.classList.add("grepper_plugin_fa");
                hasVotedIcon.classList.add("fa-trophy");
                funBadge.appendChild(hasVotedIcon);

        }
        }
    }.bind(this));



    let answerTermPopupBottom  = document.createElement("div");
        answerTermPopupBottom.classList.add("answer_term_popup_bottom")
        taysPopupInner.appendChild(answerTermPopupBottom);

    let answerTermPopupBottomButton  = document.createElement("button");
        answerTermPopupBottomButton.classList.add("answer_term_popup_bottom_button")
        answerTermPopupBottomButton.textContent="All Done";
        answerTermPopupBottomButton.addEventListener("click",function(){
         this.closeEditor();
        }.bind(this));
        answerTermPopupBottom.appendChild(answerTermPopupBottomButton);

    var removeMe = document.getElementById("grepper-editor");
    if(removeMe){
	    removeMe.parentNode.removeChild(removeMe);
    }
    document.body.appendChild(taysPopup);
}

commando.prototype.showIncorrectTermModal=function(answer){

    this.showLoginIfNot();

    this.currentEditingAnswer=answer;

 var taysPopup = document.createElement("div");
     taysPopup.classList.add("tays_popup")
     taysPopup.setAttribute("id","grepper-editor");

 var taysPopupInner = document.createElement("div");
     taysPopupInner.classList.add("tays_popup_inner_main_page")
     taysPopup.appendChild(taysPopupInner);

 var taysPopupCloseButton = document.createElement("div");
     taysPopupCloseButton.classList.add("tays_popup_close_button")
     taysPopupCloseButton.textContent="×";
     taysPopupInner.appendChild(taysPopupCloseButton);

     taysPopupCloseButton.addEventListener('click',function(){
         this.closeEditor();
     }.bind(this));

 var taysPopupHeader1 = document.createElement("div");
     taysPopupHeader1.classList.add("tays_popup_header1")
     taysPopupHeader1.textContent="Wrong Answer for My Search Feedback!";
     taysPopupInner.appendChild(taysPopupHeader1);

  // var taysPopupInputGroup = document.createElement("div");
  //     taysPopupInputGroup.classList.add("tays_popup_terms_input_group")
  //     taysPopupInner.appendChild(taysPopupInputGroup);

    
     var taysPopupInner2 = document.createElement("div");
         taysPopupInner.appendChild(taysPopupInner2);

     var radioButtons=document.createElement("div");
         radioButtons.classList.add("wrong_answer_feedback_options_holder");

     var radioButtonsLabel1=document.createElement("label");
         radioButtonsLabel1.setAttribute("for","grepper_wrong_answer_radio_1");

     var radioButtonsRadioHolder1=document.createElement("div");
         radioButtonsRadioHolder1.classList.add("wrong_answer_feedback_options_radio_holder");

     var radioButtonsRadio1=document.createElement("input");
         radioButtonsRadio1.setAttribute("type","radio");
         radioButtonsRadio1.setAttribute("id","grepper_wrong_answer_radio_1");
         radioButtonsRadio1.setAttribute("value","1");
         radioButtonsRadio1.setAttribute("name","wrong_answer_feedback_radio");
         radioButtonsRadioHolder1.appendChild(radioButtonsRadio1);

     var radioButtonsSpan1=document.createElement("span");
         radioButtonsSpan1.textContent='Answers for “'+this.maxLength(answer.term,255)+'” should not show up for the search “'+this.maxLength(this.search,255)+'”';

        radioButtonsLabel1.appendChild(radioButtonsRadioHolder1);
        radioButtonsLabel1.appendChild(radioButtonsSpan1);
        radioButtons.appendChild(radioButtonsLabel1);

     var radioButtonsLabel2=document.createElement("label");
         radioButtonsLabel2.setAttribute("for","grepper_wrong_answer_radio_2");

     var radioButtonsRadioHolder2=document.createElement("div");

         radioButtonsRadioHolder2.classList.add("wrong_answer_feedback_options_radio_holder");

     var radioButtonsRadio2=document.createElement("input");
         radioButtonsRadio2.setAttribute("type","radio");
         radioButtonsRadio2.setAttribute("id","grepper_wrong_answer_radio_2");
         radioButtonsRadio2.setAttribute("value","2");
         radioButtonsRadio2.setAttribute("name","wrong_answer_feedback_radio");
         radioButtonsRadioHolder2.appendChild(radioButtonsRadio2);

     var radioButtonsSpan2=document.createElement("span");
         radioButtonsSpan2.textContent='No answers should show up for the search term “'+this.maxLength(this.search,255)+'”';

        radioButtonsLabel2.appendChild(radioButtonsRadioHolder2);
        radioButtonsLabel2.appendChild(radioButtonsSpan2);
        radioButtons.appendChild(radioButtonsLabel2);



     let radioButtonsLabel3=document.createElement("label");
         radioButtonsLabel3.setAttribute("for","grepper_wrong_answer_radio_3");
     let radioButtonsRadioHolder3=document.createElement("div");
         radioButtonsRadioHolder3.classList.add("wrong_answer_feedback_options_radio_holder");

     let radioButtonsRadio3=document.createElement("input");
         radioButtonsRadio3.setAttribute("type","radio");

         radioButtonsRadio3.setAttribute("id","grepper_wrong_answer_radio_3");
         radioButtonsRadio3.setAttribute("name","wrong_answer_feedback_radio");
         radioButtonsRadio3.setAttribute("value","3");
         radioButtonsRadioHolder3.appendChild(radioButtonsRadio3);

     let radioButtonsSpan3=document.createElement("span");
         radioButtonsSpan3.textContent='Other Issue';
        radioButtonsLabel3.appendChild(radioButtonsRadioHolder3);
        radioButtonsLabel3.appendChild(radioButtonsSpan3);
      let otherIssueTextArea=document.createElement("textarea");
          otherIssueTextArea.setAttribute("placeholder","Please provide a short description of the issue... ");
          radioButtonsLabel3.appendChild(otherIssueTextArea);

        radioButtons.appendChild(radioButtonsLabel3);

    
        taysPopupInner2.appendChild(radioButtons);

        
    let radioButtonsList = [radioButtonsRadio1,radioButtonsRadio2,radioButtonsRadio3];
    let currentSelectedRadioButton=false;
    for (let i = 0; i < radioButtonsList.length; i++) {
         radioButtonsList[i].addEventListener("change",function(){
               if(radioButtonsList[i].checked==1){
                    currentSelectedRadioButton=radioButtonsList[i];
               }
               if (radioButtonsRadio3.checked == 1){
                    radioButtonsLabel3.classList.add("grepper_checked_active");
               } else {
                    wrongAnswerTextDescription=false;
                    radioButtonsLabel3.classList.remove("grepper_checked_active");
               }
         });
    }

    let answerTermPopupBottom  = document.createElement("div");
        answerTermPopupBottom.classList.add("answer_term_popup_bottom")
        taysPopupInner.appendChild(answerTermPopupBottom);

    let answerTermPopupBottomButton  = document.createElement("button");
        answerTermPopupBottomButton.classList.add("wrong_answer_term_popup_bottom_button");
        answerTermPopupBottomButton.textContent="Submit Feedback!";
        answerTermPopupBottomButton.addEventListener("click",function(){
            this.submitWrongAnswerFeedback(answer,currentSelectedRadioButton,otherIssueTextArea.value,taysPopupInner2,answerTermPopupBottomButton); 
         //this.closeEditor();
        }.bind(this));

        answerTermPopupBottom.appendChild(answerTermPopupBottomButton);



    var removeMe = document.getElementById("grepper-editor");
    if(removeMe){
	    removeMe.parentNode.removeChild(removeMe);
    }
    document.body.appendChild(taysPopup);
}

commando.prototype.submitWrongAnswerFeedback=function(answer,radioButton,text,taysPopupInner2,answerTermPopupBottomButton){
    if(!radioButton){
        alert('Ooop! Please select an option on why the answer is wrong!');
        return;
    }

      var postData={};
          postData.id=answer.id;
          postData.wrong_answer_reason=radioButton.value;
          postData.wrong_answer_description=text;
          postData.answer_title=answer.term;
          postData.term=this.search;

          makeRequest('POST', this.endpoint+"/feedback.php?vote=12&search_answer_id="+answer.search_answer_id+"&search_answer_result_id="+answer.search_answer_result_id+"&u="+this.user_id, JSON.stringify(postData)).then(function(data1){
               var data=JSON.parse(data1);
                 if(data.success==false && data.reason=="Unauthorized"){
                    this.showLoginPopup();
                 }else{
                    let thanksMessage=document.createElement("div");
                        thanksMessage.classList.add("tays_popup_inner_thanks_message");
                        thanksMessage.textContent="Thanks! Your answer feedback has been successfully submitted, we will use this feedback to improve what answers show in the future.";
                        taysPopupInner2.textContent="";
                        taysPopupInner2.appendChild(thanksMessage);
                        answerTermPopupBottomButton.parentNode.removeChild(answerTermPopupBottomButton);
                        setTimeout(function(){
                            this.closeEditor();
                        }.bind(this), 3000);
                 }
          }.bind(this));

}

commando.prototype.showAnswerTermsModal=function(answer){

    this.currentEditingAnswer=answer;

 var taysPopup = document.createElement("div");
     taysPopup.classList.add("tays_popup")
     taysPopup.setAttribute("id","grepper-editor");

 var taysPopupInner = document.createElement("div");
     taysPopupInner.classList.add("tays_popup_inner_main_page")
     taysPopup.appendChild(taysPopupInner);

 var taysPopupCloseButton = document.createElement("div");
     taysPopupCloseButton.classList.add("tays_popup_close_button")
     taysPopupCloseButton.textContent="×";
     taysPopupInner.appendChild(taysPopupCloseButton);

     taysPopupCloseButton.addEventListener('click',function(){
         this.closeEditor();
     }.bind(this));

 var taysPopupHeader1 = document.createElement("div");
     taysPopupHeader1.classList.add("tays_popup_header1")
     taysPopupHeader1.textContent="Answer Terms";
     taysPopupInner.appendChild(taysPopupHeader1);

 var taysPopupInputGroup = document.createElement("div");
     taysPopupInputGroup.classList.add("tays_popup_terms_input_group")
     taysPopupInner.appendChild(taysPopupInputGroup);

 var taysPopupAnswerTermInput = document.createElement("input");
     taysPopupAnswerTermInput.classList.add("tays_popup_answer_term_input");
     taysPopupAnswerTermInput.setAttribute("id","new_answer_search_term");
     taysPopupAnswerTermInput.setAttribute("placeholder","Add Answer Search Term");
     taysPopupInputGroup.appendChild(taysPopupAnswerTermInput);

     taysPopupAnswerTermInput.addEventListener("keydown", function(event) {
        if (event.key === "Enter") {
            this.addAnswerTerm();
        }
    }.bind(this));

 var taysPopupAnswerTermInputButton = document.createElement("button");
     taysPopupAnswerTermInputButton.classList.add("tays_popup_answer_term_input_button");
     taysPopupAnswerTermInputButton.textContent="Add Term";
     taysPopupAnswerTermInputButton.title="Add Search Term to Answer";
     taysPopupInputGroup.appendChild(taysPopupAnswerTermInputButton);

 var taysPopupTermsListGroup = document.createElement("div");
     taysPopupTermsListGroup.classList.add("tays_popup_terms_list_group");
     taysPopupTermsListGroup.setAttribute("id","tays_popup_terms_list_group");
     taysPopupInner.appendChild(taysPopupTermsListGroup);


        /*start stfuff*/
    makeRequest('GET',this.endpoint+"/get_answer_terms.php?answer_id="+answer.id).then(function(data){
   
      let terms_data=JSON.parse(data);
      if(terms_data.success==false && terms_data.reason=="Unauthorized"){
            this.showLoginPopup('answer_terms');
      }else{

      let terms=terms_data.terms;

    for(let i=0;i<terms.length;i++){

    let answerTermDefaultHolder = document.createElement("div");
        answerTermDefaultHolder.classList.add('answer_term_default_holder');
        taysPopupTermsListGroup.appendChild(answerTermDefaultHolder);

        if(terms[i].is_primary_answer_term){
            let primaryBadge=document.createElement("span");
                primaryBadge.classList.add("grepper_badge_primary_answer");
                primaryBadge.textContent="Primary Term";
                answerTermDefaultHolder.appendChild(primaryBadge);
        }

        let termSpan=document.createElement("span");

            termSpan.classList.add("answer_term_default_no_overflow");
            termSpan.textContent=terms[i].term;
            answerTermDefaultHolder.appendChild(termSpan);


      let btnGroup = document.createElement("div");
          btnGroup.style.cssFloat = 'right';
          answerTermDefaultHolder.appendChild(btnGroup);

      let xBtn = document.createElement("button");
          xBtn.classList.add('grepper_button_danger');
          xBtn.title="Delete";
          xBtn.textContent="×";
          xBtn.setAttribute("data-placement","top");
          xBtn.setAttribute("data-toggle","tooltip");
          xBtn.setAttribute("search_id",terms[i].id);

         if(!terms[i].is_primary_answer_term){
              btnGroup.appendChild(xBtn);
         }


      let eBtn = document.createElement("button");
          eBtn.classList.add('grepper_button_secondary');
          eBtn.classList.add('grepper_button_edit_term');
          eBtn.title="Edit";
          eBtn.setAttribute("data-placement","top");
          btnGroup.appendChild(eBtn);

      let eBtnIcon = document.createElement("i");
          eBtnIcon.classList.add('icon');
          eBtnIcon.classList.add('edit');
          eBtn.appendChild(eBtnIcon);

    let answerTermEditHolder = document.createElement("div");
        answerTermEditHolder.classList.add('answer_term_edit_holder');
        taysPopupTermsListGroup.appendChild(answerTermEditHolder);


    let answerTitleInput  = document.createElement("input");
        answerTitleInput.value=terms[i].term;
        answerTitleInput.classList.add("answer_term_edit_input")
        answerTitleInput.setAttribute("type","text");


        answerTermEditHolder.appendChild(answerTitleInput);



    let saveEditButton  = document.createElement("button");
        saveEditButton.setAttribute("search_id",terms[i].id);
        saveEditButton.classList.add('grepper_button_save_term');
        saveEditButton.textContent="✓";

        answerTermEditHolder.appendChild(saveEditButton);
            //setup the listeners
          eBtn.addEventListener("click",function(){
            answerTermEditHolder.style.display="block";
            answerTermDefaultHolder.style.display="none";
          });

     

         answerTitleInput.addEventListener("keydown", function(event) {
            if (event.key === "Enter") {
                 var data={};
                 data.id=saveEditButton.getAttribute("search_id");
                 data.term=answerTitleInput.value;
                makeRequest('POST', this.endpoint+"/update_answer_term.php",JSON.stringify(data)).then(function(datar){
                    this.showAnswerTermsModal(answer);
                }.bind(this));
            }
        }.bind(this));

          saveEditButton.addEventListener("click",function(){
         var data={};
             data.id=saveEditButton.getAttribute("search_id");
             data.term=answerTitleInput.value;
            makeRequest('POST', this.endpoint+"/update_answer_term.php",JSON.stringify(data)).then(function(datar){
                this.showAnswerTermsModal(answer);
            }.bind(this));
          }.bind(this));

         xBtn.addEventListener("click",function(){
            var r = confirm("Are you sure you want to delete this term?");
            if (r == true) {
                     var data={};
                    data.id=xBtn.getAttribute("search_id");
                makeRequest('POST', this.endpoint+"/delete_answer_term.php",JSON.stringify(data)).then(function(datar){
                    this.showAnswerTermsModal(answer);
                }.bind(this));
            }
         }.bind(this));

        }

        }
    }.bind(this));
        /*end stuff*/

    taysPopupAnswerTermInputButton.addEventListener('click',function(){
        this.addAnswerTerm();
    }.bind(this));


    let answerTermPopupBottom  = document.createElement("div");
        answerTermPopupBottom.classList.add("answer_term_popup_bottom")
        taysPopupInner.appendChild(answerTermPopupBottom);

    let answerTermPopupBottomButton  = document.createElement("button");
        answerTermPopupBottomButton.classList.add("answer_term_popup_bottom_button")
        answerTermPopupBottomButton.textContent="Close";
        answerTermPopupBottomButton.addEventListener("click",function(){
         this.closeEditor();
        }.bind(this));

        answerTermPopupBottom.appendChild(answerTermPopupBottomButton);



    var removeMe = document.getElementById("grepper-editor");
    if(removeMe){
	    removeMe.parentNode.removeChild(removeMe);
    }
    document.body.appendChild(taysPopup);
}

commando.prototype.addAnswerTerm=function(){
    var term =  document.getElementById("new_answer_search_term").value;
    if(term.length < 5){
        alert("Oops! That is little too short, terms must be at least 5 characters long");
        return;
    }
     var data={};
        data.id=this.currentEditingAnswer.id;
        data.term= term;
    makeRequest('POST', this.endpoint+"/save_answer_term.php",JSON.stringify(data)).then(function(datar){
        if(datar=="max_reached"){
            alert("Oops! Max terms reached, no more than 10 search terms per answer can be used.");
            return;
        }
        //then reload
        this.showAnswerTermsModal(this.currentEditingAnswer);
    }.bind(this));
}

//https://johnresig.com/files/htmlparser.js
commando.prototype.htmlToDom=function(html){
    let curParentNode=document.createElement("p");
    var elems=[];
        elems.push(curParentNode);
        var that=this;
        this.parseHTML( html, {
			start: function( tagName, attrs, unary ) {

               if(["b","i","a","u"].includes(tagName)){
                  var elem = document.createElement(tagName);
                }else{
                  var elem = document.createElement("span");
                }

                  for ( var attr in attrs ){
                      if(["target","rel"].includes(attrs[attr].name)){
                        elem.setAttribute(attrs[ attr ].name, attrs[ attr ].value );
                      }
                      if(attrs[attr].name =="href"){
                          if( attrs[attr].value){
                                let clean_href= attrs[attr].value.replace(/&amp;/g, '&');
                                elem.setAttribute(attrs[attr].name,clean_href);
                                if(that.startsWith(clean_href,"https://www.grepper.com/api/view_product.php?hl=1")){
                                    elem.classList.add('grepper_visit_product_button');
                                }
                            }
                       }
                  }

                    if ( curParentNode && curParentNode.appendChild ){
                        curParentNode.appendChild( elem );
                    }
                    if ( !unary ) {
                        elems.push( elem );
                        curParentNode = elem;
                    }
             
			},
			end: function( tag ) {
				elems.length -= 1;
				curParentNode = elems[ elems.length - 1 ];
			},
			chars: function( text ) {
                    text=text.replace(/&nbsp;/g, ' ');
                    text=text.replace(/&amp;/g, '&');
                    text=text.replace(/&lt;/g, '<');
                    text=text.replace(/&gt;/g, '>');
				    curParentNode.appendChild( document.createTextNode( text ) );
			},
			comment: function( text ) {
				// create comment node
			}
		});
        return elems[0];
}
commando.prototype.parseHTML=function(html, handler ){
	var startTag = /^<([-A-Za-z0-9_]+)((?:\s+\w+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>/,
		endTag = /^<\/([-A-Za-z0-9_]+)[^>]*>/,
		attr = /([-A-Za-z0-9_]+)(?:\s*=\s*(?:(?:"((?:\\.|[^"])*)")|(?:'((?:\\.|[^'])*)')|([^>\s]+)))?/g;
		
	var empty = this.makeMap("br,hr,img");
	var block = this.makeMap("div,li,p,ul");
	var inline = this.makeMap("a,b,i,b");
	var closeSelf = this.makeMap("colgroup,dd,dt,li,options,p,td,tfoot,th,thead,tr");
	var fillAttrs = this.makeMap("checked,selected");
	var special = this.makeMap("script,style");

		var index, chars, match, stack = [], last = html;
		stack.last = function(){
			return this[ this.length - 1 ];
		};

		while ( html ) {
			chars = true;

			// Make sure we're not in a script or style element
			if ( !stack.last() || !special[ stack.last() ] ) {

				// Comment
				if ( html.indexOf("<!--") == 0 ) {
					index = html.indexOf("-->");
	
					if ( index >= 0 ) {
						if ( handler.comment )
							handler.comment( html.substring( 4, index ) );
						html = html.substring( index + 3 );
						chars = false;
					}
	
				// end tag
				} else if ( html.indexOf("</") == 0 ) {
					match = html.match( endTag );
	
					if ( match ) {
						html = html.substring( match[0].length );
						match[0].replace( endTag, parseEndTag );
						chars = false;
					}
	
				// start tag
				} else if ( html.indexOf("<") == 0 ) {
					match = html.match( startTag );
	
					if ( match ) {
						html = html.substring( match[0].length );
						match[0].replace( startTag, parseStartTag );
						chars = false;
					}
				}

				if ( chars ) {
					index = html.indexOf("<");
					
					var text = index < 0 ? html : html.substring( 0, index );
					html = index < 0 ? "" : html.substring( index );
					
					if ( handler.chars )
						handler.chars( text );
				}

			} else {
				html = html.replace(new RegExp("(.*)<\/" + stack.last() + "[^>]*>"), function(all, text){
					text = text.replace(/<!--(.*?)-->/g, "$1")
						.replace(/<!\[CDATA\[(.*?)]]>/g, "$1");

					if ( handler.chars )
						handler.chars( text );

					return "";
				});

				parseEndTag( "", stack.last() );
			}

			if ( html == last )
				throw "Parse Error: " + html;
			last = html;
		}
		
		// Clean up any remaining tags
		parseEndTag();

		function parseStartTag( tag, tagName, rest, unary ) {
			tagName = tagName.toLowerCase();

			if ( block[ tagName ] ) {
				while ( stack.last() && inline[ stack.last() ] ) {
					parseEndTag( "", stack.last() );
				}
			}

			if ( closeSelf[ tagName ] && stack.last() == tagName ) {
				parseEndTag( "", tagName );
			}

			unary = empty[ tagName ] || !!unary;

			if ( !unary )
				stack.push( tagName );
			
			if ( handler.start ) {
				var attrs = [];
				rest.replace(attr, function(match, name) {
					var value = arguments[2] ? arguments[2] :
						arguments[3] ? arguments[3] :
						arguments[4] ? arguments[4] :
						fillAttrs[name] ? name : "";
					
					attrs.push({
						name: name,
						value: value,
						escaped: value.replace(/(^|[^\\])"/g, '$1\\\"') //"
					});
				});
	
				if ( handler.start )
					handler.start( tagName, attrs, unary );
			}
		}

		function parseEndTag( tag, tagName ) {
			// If no tag name is provided, clean shop
			if ( !tagName )
				var pos = 0;
				
			// Find the closest opened tag of the same type
			else
				for ( var pos = stack.length - 1; pos >= 0; pos-- )
					if ( stack[ pos ] == tagName )
						break;
			
			if ( pos >= 0 ) {
				// Close all the open elements, up the stack
				for ( var i = stack.length - 1; i >= pos; i-- )
					if ( handler.end )
						handler.end( stack[ i ] );
				
				// Remove the open elements from the stack
				stack.length = pos;
			}
		}

}
commando.prototype.makeMap=function(str){
    var obj = {}, items = str.split(",");
    for ( var i = 0; i < items.length; i++ )
        obj[ items[i] ] = true;
    return obj;
}

commando.prototype.popupWindow = function(url, w, h) {
    //const y = window.top.outerHeight / 2 + window.top.screenY - ( h / 2);
    const y = 80;
    const x = window.top.outerWidth / 2 + window.top.screenX - ( w / 2);
    return window.open(url, '', `toolbar=no, location=no, directories=no, status=no, menubar=no, scrollbars=no, resizable=no, copyhistory=no, width=${w}, height=${h}, top=${y}, left=${x}`);
}
	


function insertAfter(newNode, referenceNode) {
    referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
}

function getParameterByName(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, '\\$&');
    var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

function makeRequest (method, url, data, dontSendAuthHeaders) {

    dontSendAuthHeaders = (typeof dontSendAuthHeaders !== 'undefined') ?  dontSendAuthHeaders : false;

    var id = localStorage.getItem('grepper_user_id');
    var token  = localStorage.getItem('grepper_access_token'); 


  return new Promise(function (resolve, reject) {
    var xhr = new XMLHttpRequest();
    xhr.open(method, url);

    if(!dontSendAuthHeaders){
        if(typeof id !=='undefined'){
            xhr.setRequestHeader("x-auth-id", id);   
        }
        if(typeof token !=='undefined'){
            xhr.setRequestHeader("x-auth-token", token);   
        }
    }

    xhr.onload = function () {
      if (this.status >= 200 && this.status < 300) {
        resolve(xhr.response);
      } else {
        reject({
          status: this.status,
          statusText: xhr.statusText
        });
      }
    };
    xhr.onerror = function () {
      reject({
        status: this.status,
        statusText: xhr.statusText
      });
    };
    if(method=="POST" && data){
        xhr.send(data);
    }else{
        xhr.send();
    }
  });
}

function getRandomToken() {
    // E.g. 8 * 32 = 256 bits token
    var randomPool = new Uint8Array(32);
    crypto.getRandomValues(randomPool);
    var hex = '';
    for (var i = 0; i < randomPool.length; ++i) {
        hex += randomPool[i].toString(16);
    }
    // E.g. db18458e2782b2b77e36769c569e263a53885a9944dd0a861e5064eac16f1a
    return hex;
}

function jsUcfirst(string) {
    if(isNullString(string)){
            return '';
    }
   
    return string.charAt(0).toUpperCase() + string.slice(1);
}



function isNullString(str) {
    return (!str || 0 === str.length);
}

 
//usage ex: alert(dateToNiceDayString(new Date());
function dateToNiceDayString(myDate){
  var month=new Array();
  month[0]="Jan";
  month[1]="Feb";
  month[2]="Mar";
  month[3]="Apr";
  month[4]="May";
  month[5]="Jun";
  month[6]="Jul";
  month[7]="Aug";
  month[8]="Sep";
  month[9]="Oct";
  month[10]="Nov";
  month[11]="Dec";
  var hours = myDate.getHours();
  var minutes = myDate.getMinutes();
  var ampm = hours >= 12 ? 'pm' : 'am';
  hours = hours % 12;
  hours = hours ? hours : 12;
  minutes = minutes < 10 ? '0'+minutes : minutes;
  var strTime = hours + ':' + minutes + ampm;
  //return myDate.getDate()+" "+month[myDate.getMonth()]+" "+myDate.getFullYear()+" "+strTime;
  return month[myDate.getMonth()]+" "+myDate.getDate()+" "+myDate.getFullYear();
}
//the values here should be code mirror values


function getLangaugeSearchTerms(){
    var terms=[
        {"name":"php","terms":["php"]},
        {"name":"javascript","terms":["javascript","js","java script","javscript"]},
        {"name":"typescript","terms":["typescript","ts","type script"]},
        {"name":"css","terms":["css"]},
        {"name":"html","terms":["html"]},
        {"name":"sql","terms":["sql","mysql"]},
        {"name":"java","terms":["java"]},
        {"name":"python","terms":["python"]},
        {"name":"cpp","terms":["cpp","c++"]},
        {"name":"shell","terms":["linux","shell","install","git","ubuntu","upgrade"]},
        {"name":"objectivec","terms":["objectivec","objective c","obj c","objc"]},
        {"name":"swift","terms":["swift"]},
        {"name":"csharp","terms":["c#","csharp","c #","c sharp"]},
        {"name":"ruby","terms":["ruby"]},
        {"name":"kotlin","terms":["kotlin"]},
        {"name":"javascript","terms":["jquery","viewjs","json","angular","express","redux","ajax","node","node js","node.js","nodejs","electron","reactjs","react js","react"]},
        {"name":"python","terms":["django","pandas","flask"]},
        {"name":"php","terms":["laravel"]},
        {"name":"csharp","terms":["asp.net","asp .net","asp net",".net"]},
        {"name":"ruby","terms":["rails"]},
        {"name":"assembly","terms":["assembly"]},
        {"name":"scala","terms":["scala"]},
        {"name":"dart","terms":["dart"]},
        {"name":"elixir","terms":["elixir"]},
        {"name":"clojure","terms":["clojure"]},
        {"name":"webassembly","terms":["webassembly","web assembly"]},
        {"name":"fsharp","terms":["fsharp","f#","f #","f sharp"]},
        {"name":"erlang","terms":["erlang"]},
        {"name":"matlab","terms":["matlab","mat lab"]},
        {"name":"fortran","terms":["fortran"]},
        {"name":"perl","terms":["perl"]},
        {"name":"groovy","terms":["groovy"]},
        {"name":"julia","terms":["julia"]},
        {"name":"prolog","terms":["prolog"]},
        {"name":"pascal","terms":["pascal"]},
        {"name":"postscript","terms":["postscript","post script"]},
        {"name":"smalltalk","terms":["smalltalk"]},
        {"name":"actionscript","terms":["actionscript","action script"]},
        {"name":"basic","terms":["basic"]},
        {"name":"lisp","terms":["lisp"]},
        {"name":"abap","terms":["abap"]},
        {"name":"delphi","terms":["delphi"]},
        {"name":"vb","terms":["visual basic","vb.net","vb net"]},
        {"name":"lua","terms":["lua"]},
        {"name":"go","terms":["go"]},
        {"name":"solidity","terms":["solidity"]},
        {"name":"powershell","terms":["powershell","power shell"]},
        {"name":"gdscript","terms":["gdscript","gd script"]},
        {"name":"excel","terms":["excel"]}


   ]; 

    return terms;
}


function getAllLanguages(){
var options={
         "abap":{"name":"Abap","enabled":0},
         "actionscript":{"name":"ActionScript","enabled":0},
         "assembly":{"name":"Assembly","enabled":0},
         "basic":{"name":"BASIC","enabled":0},
         "dart":{"name":"Dart","enabled":0},
         "clojure":{"name":"Clojure","enabled":0},
         "c":{"name":"C","enabled":1},
         "cobol":{"name":"Cobol","enabled":0},
         "cpp":{"name":"C++","enabled":1},
         "csharp":{"name":"C#","enabled":1},
         "css":{"name":"CSS","enabled":1},
         "delphi":{"name":"Delphi","enabled":0},
         "elixir":{"name":"Elixir","enabled":0},
         "erlang":{"name":"Erlang","enabled":0},
         "excel":{"name":"Excel","enabled":0},
         "fortran":{"name":"Fortran","enabled":0},
         "fsharp":{"name":"F#","enabled":0},
         "gdscript":{"name":"GDScript","enabled":0},
         "go":{"name":"Go","enabled":0},
         "groovy":{"name":"Groovy","enabled":0},
         "haskell":{"name":"Haskell","enabled":0},
         "html":{"name":"Html","enabled":1},
         "java":{"name":"Java","enabled":1},
         "javascript":{"name":"Javascript","enabled":1},
         "julia":{"name":"Julia","enabled":0},
         "kotlin":{"name":"Kotlin","enabled":0},
         "lisp":{"name":"Lisp","enabled":0},
         "lua":{"name":"Lua","enabled":0},
         "matlab":{"name":"Matlab","enabled":0},
         "objectivec":{"name":"Objective-C","enabled":1},
         "pascal":{"name":"Pascal","enabled":0},
         "perl":{"name":"Perl","enabled":0},
         "php":{"name":"PHP","enabled":1},
         "postscript":{"name":"PostScript","enabled":0},
         "powershell":{"name":"PowerShell","enabled":0},
         "prolog":{"name":"Prolog","enabled":0},
         "python":{"name":"Python","enabled":1},
         "r":{"name":"R","enabled":0},
         "ruby":{"name":"Ruby","enabled":0},
         "rust":{"name":"Rust","enabled":0},
         "scala":{"name":"Scala","enabled":0},
         "scheme":{"name":"Scheme","enabled":0},
         "shell":{"name":"Shell/Bash","enabled":1},
         "smalltalk":{"name":"Smalltalk","enabled":0},
         "solidity":{"name":"Solidity","enabled":0},
         "sql":{"name":"SQL","enabled":1},
         "swift":{"name":"Swift","enabled":1},
         "typescript":{"name":"TypeScript","enabled":1},
         "vb":{"name":"VBA","enabled":0},
         "webassembly":{"name":"WebAssembly","enabled":0},
         "whatever":{"name":"Whatever","enabled":1}
    };
    return options;
}

function getLanguageSelectOptions(callback) {
    //var options=getAllLanguages();
    chrome.storage.sync.get(['grepper_user_langs'], function(all_items) {
        if(!all_items.grepper_user_langs){
            var items=getAllLanguages();
            //set if its not set
            chrome.storage.sync.set({grepper_user_langs:items }, function() {});
        }else{
            var items=all_items.grepper_user_langs;
        }
        var myOptions={};
        for (var key in items) {
            if(items[key].enabled){
                myOptions[key]=items[key].name;
            }
        } 
        callback(myOptions);
    });

}

var co=new commando();
if(window.location.hostname =="you.com"){
    if(window.location.pathname =="/search"){
        co.searchEngineId=2;
        co.youComSetupTabListeners();
        //co.runYouComSearch();
         var tbm = getParameterByName("tbm");
         //if we land on all page we run it 
         if(!tbm){
             co.runYouComSearch();
         }
    }
}else{
        co.searchEngineId=1;
        co.init();
}



