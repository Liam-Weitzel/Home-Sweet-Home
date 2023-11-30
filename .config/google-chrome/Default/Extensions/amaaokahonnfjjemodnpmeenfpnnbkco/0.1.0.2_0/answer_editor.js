function grepperAnswerEditor(commando) {
    this.commando = commando;
    this.suggestingEdit=false;
}

grepperAnswerEditor.prototype.switchToSimpleEditor = function(){

    if(this.commando.hasOwnProperty('is_page_2')){
        //we already showed it once so we just need to show it again and hide this one
        this.commando.switchToSimpleEditor();
    }else{
        this.commando.switchToSimpleEditor();
     //this.advacedAnswerHolderOuter.style.display="none";
     // this.commando.injectScript('codemirror/lib/codemirror.js', 'body',function(){
     //      this.commando.displayAnswerBox();
     // }.bind(this));
    }
}


grepperAnswerEditor.prototype.setupSourceHolder = function(noDefault){

    noDefault = (typeof noDefault !== 'undefined') ?  noDefault : false;

    this.taysPopupSourceHolder = document.createElement("div");
    this.taysPopupSourceHolder.setAttribute("id","tays_popup_source_holder");

    this.taysPopupSourceHolderLabel = document.createElement("span");
    this.taysPopupSourceHolderLabel.textContent="Source:";
    this.taysPopupSourceHolderLabel.setAttribute("id","tays_popup_source_holder_label");
    this.taysPopupSourceHolder.appendChild(this.taysPopupSourceHolderLabel);

    //add in the source input 
    this.addSourceButton = document.createElement("a");
    this.addSourceButton.textContent = "Add Source";
    this.addSourceButton.title = "Add Source";
    this.addSourceButton.setAttribute("id","tays_add_source_button");

    this.taysPopupSourceText = document.createElement("span");
    this.taysPopupSourceText.setAttribute("id","tays_popup_source_text");
    this.taysPopupSourceText.title = "Edit Source";


    this.taysPopupSourceInput = document.createElement("input");
    //this.taysPopupSourceInput.value=window.location.href;
    this.taysPopupSourceInput.setAttribute("id","tays_popup_source_input");
    this.taysPopupSourceInput.setAttribute("placeholder","http://www.your-source-website.com");

    this.taysPopupSourceInput.value = window.location.href; 


    this.taysPopupSourceInputDelete = document.createElement("span");
    this.taysPopupSourceInputDelete.setAttribute("id","tays_popup_source_delete_button");
    this.taysPopupSourceInputDelete.textContent="x";
    this.taysPopupSourceInputDelete.title = "Delete Source";
    this.taysPopupSourceInputDelete.style.display = "none";

    this.taysPopupSourceInputCheck = document.createElement("span");
    this.taysPopupSourceInputCheck.setAttribute("id","tays_popup_source_check_button");
    this.taysPopupSourceInputCheck.textContent="✓";
    this.taysPopupSourceInputCheck.title = "Set Source";
    this.taysPopupSourceInputCheck.style.display = "none";

    this.taysPopupSourceHolder.appendChild(this.addSourceButton);
    this.taysPopupSourceHolder.appendChild(this.taysPopupSourceText);
    this.taysPopupSourceHolder.appendChild(this.taysPopupSourceInput);
    this.taysPopupSourceHolder.appendChild(this.taysPopupSourceInputCheck);
    this.taysPopupSourceHolder.appendChild(this.taysPopupSourceInputDelete);


    var that=this;


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
       clearSourceInput();
    });
    function clearSourceInput(){
            that.taysPopupSourceInput.value = '';
            that.taysPopupSourceText.textContent = that.taysPopupSourceInput.value;
            that.taysPopupSourceText.style.display="none";
            that.taysPopupSourceInput.style.display="none";
            that.taysPopupSourceInputDelete.style.display="none";
            that.taysPopupSourceInputCheck.style.display="none";
            that.taysPopupSourceHolderLabel.style.display="none";
            that.addSourceButton.style.display="inline-block";

    }

    
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
            if(that.commando.isValidSource(that.taysPopupSourceInput.value)){
                that.taysPopupSourceText.textContent = that.commando.maxLength(that.taysPopupSourceInput.value,64);
                that.taysPopupSourceText.style.display="inline-block";
                that.taysPopupSourceInput.style.display="none";
                that.taysPopupSourceInputDelete.style.display="none";
                that.taysPopupSourceInputCheck.style.display="none";
            }else{
                alert("Hmm, that source is not a valid URL. Be sure to use full url. ex: http://www.mywebsite.com/mypage.php");
            }
        }
   }

   this.taysPopupSourceText.textContent = this.commando.maxLength(window.location.href,64);
   this.taysPopupSourceText.style.display="inline-block";
   this.taysPopupSourceInput.style.display="none";
   this.taysPopupSourceInputDelete.style.display="none";
   this.taysPopupSourceInputCheck.style.display="none";
   this.addSourceButton.style.display="none";
   this.taysPopupSourceHolderLabel.style.display="inline-block";

   if(noDefault){
       clearSourceInput();
   }
}

grepperAnswerEditor.prototype.displayAdvancedAnswerEditorInPage = function(content,holder,answerSource){

    this.loadCssInPage();
    this.initAdvancedAnswerHolderOuter(holder)
    this.initAdvancedAnswerHolder()
    this.initlanguageGuessDisplayHolderInPage()
    this.setupPrivatePublicAnswerButton(false,false);
    this.setupSourceHolder();

    this.commando.buildTeamsHolder(false,false,this.languageGuessDisplayHolder);

    this.addSaveButtonInPage(false,false,answerSource);
    this.setupContentListeners();
    this.setupDocumentListeners();
    this.setupPasteListener();

    this.getAnswerFormat(answerSource).then(function(formatD){
        let format=JSON.parse(formatD);
        for (let i = 0; i < format.lines.length; i++) {
            let doFucus = (i==0) ? true: false; 
            if(format.lines[i].type=="paragraph"){
                var default_text=false;
                if(format.lines[i].hasOwnProperty('placeholder')){
                    default_text  = format.lines[i].placeholder;
                }
                //answerHolder,focus,index, element, startText, placeholderText
                this.addLineP(this.advacedAnswerHolder,doFucus,false,false,false,default_text);

            }else if(format.lines[i].type=="code_snippet"){
                var notLast=(i<(format.lines.length-1));
                var ta=false;
                if(content){
                        ta=document.createElement("textarea");
                        ta.textContent=content;
                }
                this.addLineCodeSnippet(this.advacedAnswerHolder,false,ta,false,false,notLast);
            }
        }
        }.bind(this));

    

}

grepperAnswerEditor.prototype.displayAdvancedAnswerEditor = function(editingAnswer,suggestingEdit,content){

    editingAnswer = (typeof editingAnswer !== 'undefined') ?  editingAnswer : false;
    content = (typeof content !== 'undefined') ?  content : false;

    this.suggestingEdit = typeof suggestingEdit !== 'undefined' ? suggestingEdit : false;

    this.commando.showLoginIfNot();
    let isEditing=false;

    if(editingAnswer){
       isEditing=true; 

   }
    this.loadCss();

    this.initAdvancedAnswerHolderOuter()
    this.initAdvancedAnswerHolder()
    this.initlanguageGuessDisplayHolder()
    this.setupPrivatePublicAnswerButton(isEditing,editingAnswer);

    //if we are not editing do this, otherwise use above code
    if(isEditing && editingAnswer){
        this.commando.setupSourceInput(isEditing,editingAnswer);
        this.advacedAnswerHolderOuter.appendChild(this.commando.taysPopupSourceHolder);
    }else{
        this.setupSourceHolder(true);
        this.advacedAnswerHolderOuter.appendChild(this.taysPopupSourceHolder);
    }



    this.commando.buildTeamsHolder(editingAnswer,isEditing,this.languageGuessDisplayHolder);

    this.addSaveButton(editingAnswer,isEditing);
    this.setupContentListeners();
    this.setupDocumentListeners();
    this.setupPasteListener();


    if(editingAnswer){
      var answer_content=JSON.parse(editingAnswer.answer);
        for(var i=0;i<answer_content.tags.length;i++){
            if(answer_content.tags[i].tag=="p"){
                var contentDom=this.commando.htmlToDom(answer_content.tags[i].content);
                this.addLineP(this.advacedAnswerHolder,false,false,contentDom);
            }else if(answer_content.tags[i].tag=="textarea"){
                var ta = document.createElement("textarea");
                    ta.textContent=answer_content.tags[i].content;
                    this.addLineCodeSnippet(this.advacedAnswerHolder,false,ta,answer_content.tags[i].code_language);

                    //we need to add empty p after code snippet if there is not one...
                    if(i==(answer_content.tags.length-1) || (answer_content.tags[i+1].tag=="textarea")){
                        this.addLineP(this.advacedAnswerHolder,false,false,false,false,false,true);
                    }

            }
        }

    }else{
      this.getAnswerFormat().then(function(formatD){
        let format=JSON.parse(formatD);
        for (let i = 0; i < format.lines.length; i++) {
            let doFucus = (i==0) ? true: false; 
            if(format.lines[i].type=="paragraph"){
                var default_text=false;
                if(format.lines[i].hasOwnProperty('placeholder')){
                    default_text  = format.lines[i].placeholder;
                }
                //answerHolder,focus,index, element, startText, placeholderText
                this.addLineP(this.advacedAnswerHolder,doFucus,false,false,false,default_text);

            }else if(format.lines[i].type=="code_snippet"){
                var notLast=(i<(format.lines.length-1));
                var ta=false;
                if(content){
                        ta=document.createElement("textarea");
                        ta.textContent=content;
                }
                this.addLineCodeSnippet(this.advacedAnswerHolder,false,ta,false,false,notLast);
            }
        }
        }.bind(this));

    }
}

grepperAnswerEditor.prototype.focus = function(p){
        //  s = window.getSelection(),
        //  r = document.createRange();
        //  r.setStart(p, 0);
        //  r.setEnd(p, 0);
        //  s.removeAllRanges();
        //  s.addRange(r);
        //  p.focus();


  var range = document.createRange();
        range.selectNodeContents(p);
        range.collapse(false);
        var sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);

}

grepperAnswerEditor.prototype.getAnswerFormat = function(answerSource){

        answerSource = (typeof answerSource !== 'undefined') ?  answerSource : 2;

        return makeRequest('GET', this.commando.endpoint+"/get_answer_format.php?s="+encodeURIComponent(this.commando.search)+"&answer_source="+answerSource);

  //var format={};
  //    format.lines=[];
  //    format.lines.push({"type":"paragraph",'placeholder':'Tell your story...'});
  //    format.lines.push({"type":"code_snippet"});
  //    return format;
}

grepperAnswerEditor.prototype.addLineP=function(answerHolder,focus,index, element, startText, placeholderText,ignore_on_empty){

        focus = (typeof focus !== 'undefined') ?  focus : false;
        index = (typeof index !== 'undefined') ?  index : false;
        element = (typeof element !== 'undefined') ?  element : false;
        startText = (typeof startText !== 'undefined') ?  startText : false;
        placeholderText = (typeof placeholderText !== 'undefined') ?  placeholderText : false;
        ignore_on_empty = (typeof ignore_on_empty !== 'undefined') ?  ignore_on_empty : false;

        let p = document.createElement("p");

        if(startText){
            p.textContent=startText;
        }else if(placeholderText){
           p.setAttribute("placeholder",placeholderText);
           p.classList.add('grepper_show_placeholder');
        }
        if(element){
           p=element;
        }

       if(!element || !element.textContent){
        let br = document.createElement("br");
            p.appendChild(br);
       }
        

        p.setAttribute("tabindex","0");
        if(ignore_on_empty){
            p.ignore_on_empty=true;
        }

        if(index !== false){
            answerHolder.insertBefore(p, answerHolder.children[index]);
        }else{
            answerHolder.appendChild(p);
        }
        if(focus){
          this.focus(p);
        }
        return p;
}


grepperAnswerEditor.prototype.setupPrivatePublicAnswerButton =function(isEditing,editingAnswer){
    this.publicPrivateHolder = document.createElement("a");
    this.publicPrivateHolder.setAttribute("id","grepper_public_private_holder");

    if(isEditing && editingAnswer.is_private == 1){
        this.publicPrivateHolder.title="Answer is Private. Change to Public.";
        this.publicPrivateHolder.classList.add("grepper_public_private_holder_private");
    }else{
        this.publicPrivateHolder.title="Answer is Public. Change to Private.";
        this.publicPrivateHolder.classList.add("grepper_public_private_holder_public");
    }

    let old_this=this.commando;
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


    //setup toggle for regular answer

    if(!isEditing){
        this.answerTypeHolder = document.createElement("a");
        this.answerTypeHolder.setAttribute("id","grepper_answer_type_holder");
        this.answerTypeHolder.title="Switch to simple code snippet editor";
        this.answerTypeHolder.addEventListener("click",function(){
            this.switchToSimpleEditor();
        }.bind(this));

        this.languageGuessDisplayHolder.appendChild(this.answerTypeHolder);
    }

    this.languageGuessDisplayHolder.appendChild(this.publicPrivateHolder);
}

grepperAnswerEditor.prototype.initAdvancedAnswerHolderOuter =function(holder){

    holder = (typeof holder !== 'undefined') ?  holder : false;

    this.advacedAnswerHolderOuter=document.createElement("div");
    this.advacedAnswerHolderOuter.classList.add("grepper_answer_enhanced_outer");
    this.advacedAnswerHolderOuter.setAttribute("id","grepper_answer_enhanced_outer")
    if(holder){
        holder.appendChild(this.advacedAnswerHolderOuter);
    }else{
        this.commando.statsDom.insertBefore(this.advacedAnswerHolderOuter,this.commando.statsDom.childNodes[0]);
    }
}

grepperAnswerEditor.prototype.initAdvancedAnswerHolder =function(){
    this.advacedAnswerHolder=document.createElement("div");
    this.advacedAnswerHolder.classList.add("grepper_answer_enhanced");
    this.advacedAnswerHolder.setAttribute("contenteditable","true");
    this.advacedAnswerHolderOuter.appendChild(this.advacedAnswerHolder);
}

//this is really menu bar for answer
grepperAnswerEditor.prototype.initlanguageGuessDisplayHolder =function(){

    this.languageGuessDisplayHolder = document.createElement("div");
    this.languageGuessDisplayHolder.setAttribute("id","languange_guess_display_holder");



    this.answerOptionsTitleEdit= document.createElement("div");
    this.answerOptionsTitleEdit.classList.add("grepper_answers_options_title_editing");
    this.answerOptionsTitleEdit.textContent=this.commando.search;
    this.languageGuessDisplayHolder.appendChild(this.answerOptionsTitleEdit);

    this.advacedAnswerHolderOuter.insertBefore(this.languageGuessDisplayHolder,this.advacedAnswerHolder);
}

grepperAnswerEditor.prototype.initlanguageGuessDisplayHolderInPage =function(){

    this.languageGuessDisplayHolder = document.createElement("div");
    this.languageGuessDisplayHolder.setAttribute("id","languange_guess_display_holder");

    this.answerOptionsTitleEdit= document.createElement("div");
    this.answerOptionsTitleEdit.classList.add("grepper_answers_options_title_editing");
    this.answerOptionsTitleEdit.textContent=this.commando.codeSearch.search;
    this.languageGuessDisplayHolder.appendChild(this.answerOptionsTitleEdit);

    this.advacedAnswerHolderOuter.insertBefore(this.languageGuessDisplayHolder,this.advacedAnswerHolder);
}







grepperAnswerEditor.prototype.getContentFormatted =function(){
    let children= this.advacedAnswerHolder.children;
    let content={};
        content.tags=[];

       for(let i=0; i<children.length; i++){
            if(children[i].classList.contains("TaysCodeMirror")){
                let cl=children[i].previousElementSibling.previousElementSibling.firstChild.value
                content.tags.push({"tag":"textarea","content":children[i].TaysCodeMirror.getValue(),"code_language":cl});
            }else if(children[i].tagName.toLowerCase()=="p"){

                if(!children[i].textContent && children[i].ignore_on_empty){

                }else{
                    content.tags.push({"tag":"p","content":children[i].innerHTML});
                }
                
            }else if(children[i].tagName.toLowerCase()=="textarea"){
                continue;
            }else if(children[i].classList.contains("grepper_ae_language_select")){
                continue;
            }else{
                //contentFormated.appendChild(children[i].cloneNode(true));
            }
        }
        return JSON.stringify(content);
}

grepperAnswerEditor.prototype.getAnswerPrimaryLanguage =function(){
    let children= this.advacedAnswerHolder.children;
    let content={};
        content.tags=[];

        //use first code snippet 
       for(let i=0; i<children.length; i++){
            if(children[i].classList.contains("grepper_ae_language_select")){
                return children[i].firstChild.value;
            }
        }
        //otherwise guess the laguage
        //otherwise return whaterver and try to fix on the backend w/ the term
        return "whatever";
}

grepperAnswerEditor.prototype.addSaveButton =function(editingAnswer,isEditing,answerSource){

    answerSource = (typeof answerSource !== 'undefined') ?  answerSource : 2;
    
    this.codeResultsSave = document.createElement("button");
    this.codeResultsSave.textContent="Save";
    this.codeResultsSave.setAttribute("id","commando_save_answer");



    this.codeResultsSave.addEventListener('click',function(){

    //remove all menus
    this.removeAddObjectsMenuFull();

    //umm what is answer??
     var answer=this.getContentFormatted();
    
        var codeSearch={};
            codeSearch.results=this.commando.resultsURLS;
            codeSearch.search=this.commando.search;

        var data={};
        data.answer=answer;
        data.user_id=this.commando.user_id;
        data.codeSearch=codeSearch;
        data.source=answerSource;
        //data.language = this.editorCurrentLanguageSelect.value;
        data.language = this.getAnswerPrimaryLanguage();
        data.is_advanced = 1; 

        if(this.publicPrivateHolder.classList.contains("grepper_public_private_holder_private")){
            data.is_private = 1;
        }else{
            data.is_private = 0;
        }

     
        //if we are editing use this source otherwise use content page source
       if(isEditing && editingAnswer){
             if(this.commando.taysPopupSourceInput.value && this.commando.isValidSource(this.commando.taysPopupSourceInput.value)){
                  data.source_url=this.commando.taysPopupSourceInput.value;
              }else{
                  data.source_url="";
              }
        }else{
             if(this.taysPopupSourceInput.value && this.commando.isValidSource(this.taysPopupSourceInput.value)){
                  data.source_url=this.taysPopupSourceInput.value;
              }else{
                  data.source_url="";
              }
        }

        if(isEditing){
            data.id=editingAnswer.id;    
        }

        var saveUrl = this.commando.endpoint+"/save_answer.php";
        if(isEditing){
            saveUrl =  this.commando.endpoint+"/update_answer.php";
        }
        if(isEditing && this.suggestingEdit){
            saveUrl =  this.commando.endpoint+"/suggest_edit.php";
        }

     // //save answer to teams
      if(this.commando.teams.length){
           data.team_ids=[];
           for(var i=0;i<this.commando.teamIcons.length;i++){
               if(this.commando.teamIcons[i].classList.contains("grepper_team_icon_active")){
                   data.team_ids.push(this.commando.teamIcons[i].getAttribute("grepper_team_id"));
               }
           }
      }
        
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
                this.commando.addUserCodeLanguage(dataR.add_language);
            }

            if(dataR.success==false && dataR.reason=="Unauthorized"){
                this.commando.showLoginPopup();
                return false;
            }else if(dataR.payment_required){
                var r = confirm("Oops! Looks like you need to activate Grepper, Activate now?");
                if (r == true) {
                    window.open("https://www.codegrepper.com/checkout/checkout.php", "_blank");
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

    this.codeResultsSaveHolder.appendChild(this.codeResultsSave);

    this.advacedAnswerHolderOuter.appendChild(this.codeResultsSaveHolder);

}

grepperAnswerEditor.prototype.addSaveButtonInPage =function(editingAnswer,isEditing,answerSource){

    answerSource = (typeof answerSource !== 'undefined') ?  answerSource : 2;


   var taysPopupSaveButtonHolder = document.createElement("div");

    this.codeResultsSave = document.createElement("button");
    this.codeResultsSave.textContent="Save Answer";
    this.codeResultsSave.classList.add("grepper_save_button");



    this.codeResultsSave.setAttribute("id","commando_save_answer");

    this.codeResultsSave.addEventListener('click',function(){


    this.removeAddObjectsMenuFull();
     if(this.commando.codeSearch.search.length < 2){
          if(document.getElementById("grepper_answer_title")){
               document.getElementById("grepper_answer_title").style.border="1px solid red";
          }
          alert("Please enter the search term that will trigger this answer.");
          return false;
    }

    //umm what is answer??
     var answer=this.getContentFormatted();

        var data={};
        data.answer=answer;
        data.user_id=this.commando.user_id;
        data.codeSearch=this.commando.codeSearch;
        data.source=answerSource;
        data.language = this.getAnswerPrimaryLanguage();
        data.is_advanced = 1; 

        if(this.publicPrivateHolder.classList.contains("grepper_public_private_holder_private")){
            data.is_private = 1;
        }else{
            data.is_private = 0;
        }

      if(this.taysPopupSourceInput.value && this.commando.isValidSource(this.taysPopupSourceInput.value)){
          data.source_url=this.taysPopupSourceInput.value;
      }else{
          data.source_url="";
      }

//////if(isEditing){
//////    data.id=editingAnswer.id;    
//////  }

        var saveUrl = this.commando.endpoint+"/save_answer.php";
        if(isEditing){
            saveUrl =  this.commando.endpoint+"/update_answer.php";
        }

     // //save answer to teams
      if(this.commando.teams.length){
           data.team_ids=[];
           for(var i=0;i<this.commando.teamIcons.length;i++){
               if(this.commando.teamIcons[i].classList.contains("grepper_team_icon_active")){
                   data.team_ids.push(this.commando.teamIcons[i].getAttribute("grepper_team_id"));
               }
           }
      }
        
        var spinnerIcon = document.createElement("div"); 
            spinnerIcon.classList.add('grepper_loading_ring');
            this.codeResultsSave.textContent=""
            this.codeResultsSave.appendChild(spinnerIcon);

        
        var spinnerIconC = document.createElement("span"); 
            spinnerIconC.textContent="Saving";
            this.codeResultsSave.appendChild(spinnerIconC);
            this.codeResultsSave.disabled=true;


        makeRequest('POST',saveUrl,JSON.stringify(data),this.commando.user_id,this.commando.access_token).then(function(responseData){

            //re-enable
            this.codeResultsSave.removeAttribute("disabled");
            this.codeResultsSave.textContent="Save";

            var dataR=JSON.parse(responseData); 

              if(dataR.add_language){
                  this.commando.addUserCodeLanguage(dataR.add_language);
              }

            if(dataR.success==false && dataR.reason=="Unauthorized"){
                this.commando.showLoginPopup();
                return false;
            }else{
                this.commando.closeEditor();
                this.commando.showGrepperAnswerSavedDialog();
            }

        }.bind(this));


    }.bind(this));

  //this.codeResultsSaveHolder = document.createElement("div");
  //this.codeResultsSaveHolder.setAttribute("id","commando_save_answer_holder");

var taysPopupSaveButtonBottomNav = document.createElement("div");
    taysPopupSaveButtonBottomNav.classList.add("grepper_bottom_nav");

    taysPopupSaveButtonBottomNav.appendChild(this.codeResultsSave);
    taysPopupSaveButtonHolder.appendChild(taysPopupSaveButtonBottomNav);



    //this.codeResultsSaveHolder.appendChild(this.codeResultsSave);

    this.advacedAnswerHolderOuter.appendChild(taysPopupSaveButtonHolder);

}




grepperAnswerEditor.prototype.loadCss = function(){
    var faCss=document.createElement("link")
        faCss.setAttribute("rel","stylesheet")
        faCss.setAttribute("type","text/css");
        faCss.href=chrome.runtime.getURL("semantic/answer_editor_semantic.css");
        document.body.appendChild(faCss);
}

grepperAnswerEditor.prototype.loadCssInPage = function(){
    var faCss=document.createElement("link")
        faCss.setAttribute("rel","stylesheet")
        faCss.setAttribute("type","text/css");
        faCss.href=chrome.runtime.getURL("semantic/answer_editor_semantic.css");
        document.body.appendChild(faCss);
    var faCss=document.createElement("link")
        faCss.setAttribute("rel","stylesheet")
        faCss.setAttribute("type","text/css");
        faCss.href=chrome.runtime.getURL("css/answer_editor.css");
        document.body.appendChild(faCss);
}



grepperAnswerEditor.prototype.addLineCodeSnippet=function(answerHolder,currentLine,textArea,language,focus,notLast){

       let newTextArea=document.createElement("textarea");

        focus = (typeof focus !== 'undefined') ?  focus : false;
        notLast = (typeof notLast !== 'undefined') ?  notLast : false;

       if(textArea){
            newTextArea=textArea;
       }


       if(currentLine){
            currentLine.parentNode.insertBefore(newTextArea, currentLine.nextSibling);
            //so if its last we need to add  the p after this guy
            if(!newTextArea.nextSibling && !notLast){
                this.addLineP(answerHolder,false,this.getMyIndex(newTextArea)+1);
            }
            currentLine.parentNode.removeChild(currentLine);//then remove this p ( we don't need it)

       }else{
            answerHolder.appendChild(newTextArea);

            //if we are passing textare we are in answer editing mode (we won't need newline)
            if(!textArea && !notLast){
                this.addLineP(answerHolder);
            }
            //currentLine.parentNode.removeChild(currentLine);//what does this do???
       }
       

       if(newTextArea.previousElementSibling){
            newTextArea.previousElementSibling.classList.add("no_bottom_padding");
       }

       

       var d1=document.createElement("div");
           d1.setAttribute("contenteditable","false");
           d1.classList.add("grepper_code_wrapper_divs");
           d1.classList.add("grepper_code_wrapper_divs1");
           d1.addEventListener("mousedown",function(event){
               event.preventDefault();
               event.stopPropagation();
               if(d1.previousElementSibling && d1.previousElementSibling.tagName=="P"){
                 this.focus(d1.previousElementSibling);
               }else{
                 this.addLineP(answerHolder,true,this.getMyIndex(d1));
               }

           }.bind(this));

           answerHolder.insertBefore(d1,newTextArea);

       let d2=document.createElement("div");
           d2.setAttribute("contenteditable","false");
           d2.classList.add("grepper_code_wrapper_divs");
           if(newTextArea.nextElementSibling){
           answerHolder.insertBefore(d2,newTextArea.nextElementSibling);
           }else{
            answerHolder.appendChild(d2);
           }


           d2.addEventListener("mousedown",function(event){
               event.preventDefault();
               event.stopPropagation();
               if(d2.nextSibling && d2.nextSibling.tagName=="P"){
                   //just focus on the p otherwise create a new P
                 this.focus(d2.nextSibling);
               }else{
                 this.addLineP(answerHolder,true,this.getMyIndex(d2)+1);
               }

           }.bind(this));



       this.addCodeMirrorToTextArea(answerHolder,newTextArea,language,focus);
}


grepperAnswerEditor.prototype.addCodeMirrorToTextArea=function(answerHolder,newTextArea,language,focus){

    focus = (typeof focus !== 'undefined') ?  focus : false;

    this.commando.guessCodeLanguage(function(languageGuessRaw){
      if(language){
          languageGuessRaw = language;
      }

      //languageGuessRaw="groovy";

this.commando.languangeNametoTaysCodeMirrorName(languageGuessRaw,function(mimeType){
    //hack to give time to load to proper files
     setTimeout(function(){ 

        let codeSnip=TaysCodeMirror.fromTextArea(newTextArea,{
                lineNumbers: false,
                theme:"prism-okaidia",
                mode: mimeType,
                viewportMargin: Infinity
        });
        let codeSnipDom=codeSnip.getWrapperElement();
            codeSnipDom.classList.add("TaysCodeMirrorMarginBottom");

        if(focus){
            codeSnip.focus();
        }

      let selectBox  = document.createElement('select');
      selectBox.addEventListener('change',function(){
          let l=selectBox.value;
          this.commando.languangeNametoTaysCodeMirrorName(l,function(mimeType){
               //this.commando.loadedCodeMirrorModes=[];
               codeSnip.setOption("mode", mimeType);
          }.bind(this));
      }.bind(this));
    
    getLanguageSelectOptions(function(options){
        for (var key in options) {
              var opt = document.createElement('option');
                opt.value = key;
                opt.textContent = options[key];
              if(languageGuessRaw===key){
                  opt.setAttribute("selected", "selected");
              }
               selectBox.appendChild(opt);
        }
    }.bind(this));

     let grepperOptionsHolder =  document.createElement('div');
         grepperOptionsHolder.classList.add("grepper_ae_language_select");
         grepperOptionsHolder.setAttribute("contenteditable","false");
         grepperOptionsHolder.appendChild(selectBox);

         answerHolder.insertBefore(grepperOptionsHolder,newTextArea);


     codeSnip.on('keydown', function(editor,event){
           if(event.key == "Backspace"){
               let text = editor.doc.getValue()
                   if(!text){
                       event.preventDefault();
                       let we=codeSnip.getWrapperElement();

                        answerHolder.removeChild(we.previousElementSibling);
                        answerHolder.removeChild(we.previousElementSibling);
                        answerHolder.removeChild(we.previousElementSibling);
                        answerHolder.removeChild(we.nextElementSibling);

                        setTimeout(function(){
                        
                            if(we.previousElementSibling && we.previousElementSibling.classList.contains("no_bottom_padding")){
                                we.previousElementSibling.classList.remove("no_bottom_padding");
                            }

                            this.findFocusOnElRightBeforeMyRemoval(we);
                            answerHolder.removeChild(we);
                            this.addPIfNeeded();
                        }.bind(this),20);

                   }
           }
       }.bind(this));
       }.bind(this), 1);
    }.bind(this));
}.bind(this));


  // if(newTextArea.getAttribute('code_language')){
  //         grepperOptionsHolder.value= newTextArea.getAttribute('code_language');
  //         this.languangeNametoTaysCodeMirrorName(mySelect.value,function(mimeType){
  //                 codeSnip.setOption("mode", mimeType);
  //         }.bind(this));
  // }

}


grepperAnswerEditor.prototype.showAddContentPopupsAll=function(el){

        this.currentLine=el;
        this.addContentIconsHolder=document.createElement("div");
        this.addContentIconsHolder.classList.add("add_content_icon_holder");

        this.addContentIconsHolder.style.left="0px";

        let code=document.createElement("div");
            code.classList.add("content_add_element")
            code.classList.add("content_add_element_code")
            code.classList.add("greppericon")
            code.classList.add("grepper_code")
            code.setAttribute("contenteditable","false");

            //code.textContent="</>";
            code.addEventListener("mousedown",function(){
                this.removeAddObjectsMenuFull();
                this.addLineCodeSnippet(this.advacedAnswerHolder,el,false,false,true);
            }.bind(this));

        this.addContentIconsHolder.appendChild(code);
       el.appendChild(this.addContentIconsHolder);
}

grepperAnswerEditor.prototype.showAddContentPopupIcon=function(el,maxLength){
    maxLength = (typeof maxLength !== 'undefined') ?  maxLength : 1;
    this.removeAddObjectsMenuFull();
    if(el.textContent.length < maxLength){
        this.addContentIconMain=document.createElement("div");
        this.addContentIconMain.classList.add("add_content_icon_main");
        this.addContentIconMain.classList.add("content_add_element");
        this.addContentIconMain.classList.add("greppericon");
        this.addContentIconMain.classList.add("grepper_add");
        this.addContentIconMain.setAttribute("contenteditable","false");
        this.addContentIconMain.setAttribute("tabindex","0")
        //this.addContentIconMain.textContent='＋';
        this.addContentIconMain.addEventListener("mousedown",function(event){
            if(this.addContentIconMain.classList.contains("grep_selected")){
                this.addContentIconMain.classList.remove('grep_selected');
                this.removeAddObjectsMenuOnly();
                document.activeElement.blur();
                event.preventDefault();
            }else{
                //we need to remove focus
                document.activeElement.blur();
                event.preventDefault();
                this.showAddContentPopupsAll(el);
                this.addContentIconMain.classList.add('grep_selected');
            }
        }.bind(this));

        //let elOffset=this.offset(el);
        //this.addContentIconMain.style.top=(elOffset.top)+"px";
        this.addContentIconMain.style.left="-38px";

        //setTimeout(function(){
            el.appendChild(this.addContentIconMain);
        //}.bind(this),10);
    }
}
function getChildIndex(node) {
  return Array.prototype.indexOf.call(node.parentNode.childNodes, node);
}


grepperAnswerEditor.prototype.removeEditorBoxIfNeeded=function(event){
    if(this.currentEditorBox){
        if(!event || !event.composedPath().includes(this.currentEditorBox)){
            this.currentEditorBox.parentNode.removeChild(this.currentEditorBox);
            this.currentEditorBox=false;
        }
    }
}

grepperAnswerEditor.prototype.setupDocumentListeners=function(){

/*
 document.getElementById("grepper_writeup_bottom").addEventListener("click",function(){
     //maybe only add if needed
    this.addLine(true);
 }.bind(this));
 */

 document.addEventListener("mousedown", function(event) {
     this.removeEditorBoxIfNeeded(event);
 }.bind(this), false);

 document.addEventListener("keydown", function(event) {
     this.keyspressedSinceLastSave+=1;
     this.removeEditorBoxIfNeeded(event);
 }.bind(this), false);

}


grepperAnswerEditor.prototype.findFocusOnElRightBeforeMyRemoval=function(el){
                    var focusEl=false;
                    if(el.previousElementSibling){
                        focusEl=el.previousElementSibling;
                    }
                    if(focusEl.tagName=="DIV"){
                        if(focusEl.previousElementSibling){
                            focusEl=focusEl.previousElementSibling;
                        }else{
                            focusEl=false;
                        }
                    }
                    if(focusEl){
                        if(focusEl.TaysCodeMirror){
                            focusEl.TaysCodeMirror.focus();
                        }else{
                            this.focus(focusEl);
                        }
                        //we try to find element b4 to focus on
                    }else{
                            var focusEl=false;
                            if(el.nextElementSibling){
                                focusEl=el.nextElementSibling;
                            }
                            if(focusEl.tagName=="DIV"){
                                if(focusEl.nextElementSibling.nextElementSibling.nextElementSibling){
                                    focusEl=focusEl.nextElementSibling.nextElementSibling.nextElementSibling;
                                }else{
                                    focusEl=false;
                                }
                            }

                            if(focusEl){
                                if(focusEl.TaysCodeMirror){
                                    focusEl.TaysCodeMirror.focus();
                                }else{
                                    this.focus(focusEl);
                                }
                            }

                   }
}

grepperAnswerEditor.prototype.setupContentListenersKeyDown=function(event){
          let el=this.getCurrentElement();

        //so double space press will stop the inline styling...
      //if(el && ["I","B","U"].includes(el.tagName)){
      //   if(event.key==" "){
      //            if(el.lastPressedKey == event.key){//note that space there is copy/pasted regular space from vim did not work
      //                event.stopPropagation();
      //                event.preventDefault();
      //                if(el.tagName == "B"){
      //                    document.execCommand('bold');
      //                }else if(el.tagName=="I"){
      //                    document.execCommand('italic');
      //                }else if(el.tagName=="U"){
      //                    document.execCommand('underline');
      //                }
      //            }
      //    }
      //    el.lastPressedKey=event.key;
      //}

          if(event.target.parentNode.tagName=="FIGURE"){
              this.onFigureKeyDown(event,event.target.parentNode)
          }
          if(event.target.tagName=="FIGURE"){
              this.onFigureKeyDown(event,event.target);
          }




          if(event.key=="Backspace"||event.key=="Delete"){
              if(el && ["P","H1","H2"].includes(el.tagName)){
                  this.showAddContentPopupIcon(el,2);

                if(!el.textContent){
                    event.preventDefault();
                
                   this.findFocusOnElRightBeforeMyRemoval(el);

                  //always remove this element
                  el.parentNode.removeChild(el);

                  this.addPIfNeeded();
                  
                 //add 1 p if we are out of elements

                    
                    //or its the last element after a code snippet....
                }
              }
          }else{
                this.removeAddObjectsMenuFull();
          }

          //always create a new p on
          if(event.key=="Enter"){
            if(["H1","H2","H3","H4","H5"].includes(el.tagName)){
                event.preventDefault();
                if(el.tagName=="H1" && el.nextSibling && elnextSibling.tagName=="H2"){
                    this.focus(el.nextSibling);
                }else{
                    this.addLine(true,this.getMyIndex(el)+1);
                }
            }
            if(["LI"].includes(el.tagName)){
                if(!el.textContent){
                    event.preventDefault();
                    this.addLine(true,this.getMyIndex(el.parentNode)+1);
                    el.parentNode.removeChild(el);
                }
            }

            //when they hit enter on p we show add button
            if(["P"].includes(el.tagName)){
             // event.preventDefault();
             // this.addLineP(this.advacedAnswerHolder,true,this.getMyIndex(el)+1);
              setTimeout(function(){
                  if(!el.nextSibling.textContent){
                    this.showAddContentPopupIcon(el.nextSibling);
                  }
              }.bind(this),10);
                
            }
          }


}


grepperAnswerEditor.prototype.addPIfNeeded=function(event){
      if(!this.advacedAnswerHolder.childElementCount){
            this.addLineP(this.advacedAnswerHolder,true,false,false,false,false);
      }
}
grepperAnswerEditor.prototype.setupContentListenersKeyUp=function(event){

       let el=this.getCurrentElement();
        if(event.key==" "){
             if(["P"].includes(el.tagName)){
                if(el.textContent){
                    if(el.textContent=="* "){
                        this.startList(el,"ul");
                   }
                }
            }
        }

    //remove place holder if wehave some textContent
      if(el.getAttribute("placeholder")){
              if(el.textContent){
                  if(el.classList.contains("grepper_show_placeholder")){
                        el.classList.remove("grepper_show_placeholder");
                  }
              }
        }

        
        if(event.key=="."){
            if(["P"].includes(el.tagName)){
                if(el.textContent){
                    if(el.textContent.length==2){
                       if(Number.isInteger(parseFloat(el.textContent.charAt(0)))){
                            this.startList(el,"ol");
                       }
                   }
                }
            }
        }
         if(event.key=="Backspace"||event.key=="Delete"){
              if(el && ["P"].includes(el.tagName)){
                  if(el.getAttribute("placeholder")){
                      if(el.textContent.replace("＋","").length < 1 ){
                          if(!el.classList.contains("grepper_show_placeholder")){
                                el.classList.add("grepper_show_placeholder");
                          }
                      }
                  }
              }
              //this.addPIfNeeded();

          }

         if(event.key=="Enter"){
             if(["P"].includes(el.tagName)){
                  setTimeout(function(){
                       if(el.hasAttribute("placeholder")){
                          el.removeAttribute("placeholder");
                       }
                  }.bind(this),1);
            }
         }

}
grepperAnswerEditor.prototype.setupContentListeners=function(){

      this.advacedAnswerHolder.addEventListener("mouseup", function(event) {

         if(["H1","H2","A","P","H3","H4","I","B","LI","H5","U"].includes(event.target.tagName)){
          let currentSelection= window.getSelection().getRangeAt(0).cloneRange();
          if(!currentSelection.collapsed){
              this.showEditorBox(event.target,currentSelection);
          }
         }
      }.bind(this));

       this.advacedAnswerHolder.addEventListener("focusin",function(event){
         if(["P"].includes(event.target.tagName)){
            this.showAddContentPopupIcon(event.target);
          }
       }.bind(this));

      //this prevent google overrides
      this.advacedAnswerHolder.addEventListener("keypress",function(event){
          event.stopPropagation();
      });

      this.advacedAnswerHolder.addEventListener("keydown",function(event){
            this.setupContentListenersKeyDown(event);
      }.bind(this), false);

     this.advacedAnswerHolder.addEventListener('keyup',function(event){
            this.setupContentListenersKeyUp(event);
    }.bind(this));

//  this.setupPasteListener();
}

grepperAnswerEditor.prototype.removeAddObjectsMenuOnly = function(){
   if(this.addContentIconsHolder){
        this.addContentIconsHolder.parentNode.removeChild(this.addContentIconsHolder);
        this.addContentIconsHolder=false;
   }
}

grepperAnswerEditor.prototype.removeAddObjectsMenuFull = function(){
    this.removeAddObjectsMenu();
   if(this.addContentIconsHolder){
        this.addContentIconsHolder.parentNode.removeChild(this.addContentIconsHolder);
        this.addContentIconsHolder=false;
   }

}

grepperAnswerEditor.prototype.removeAddObjectsMenu = function(){
   if(this.addContentIconMain){
        this.addContentIconMain.parentNode.removeChild(this.addContentIconMain);
        this.addContentIconMain=false;
    }
}

grepperAnswerEditor.prototype.getCurrentElement=function(){
   if (window.getSelection){
       if(window.getSelection().anchorNode instanceof Element){
          return  window.getSelection().anchorNode;
       }else{
        return window.getSelection().anchorNode.parentNode;
       }
   }
   return false;
}

grepperAnswerEditor.prototype.offset=function(el) {
    var rect = el.getBoundingClientRect(),
    scrollLeft = window.pageXOffset || document.documentElement.scrollLeft,
    scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    return { top: rect.top + scrollTop, left: rect.left + scrollLeft }
}
grepperAnswerEditor.prototype.getMyIndex=function(el){
    var nodes = Array.prototype.slice.call(this.advacedAnswerHolder.children );
    return nodes.indexOf(el);
}
grepperAnswerEditor.prototype.cursorPosition=function(){
    var sel = document.getSelection();
    var pos = sel.toString().length;
    if(sel.anchorNode != undefined) sel.collapseToEnd();

    return pos;
}

grepperAnswerEditor.prototype.showEditorBox=function(el,currentSelection){
    if(this.currentEditorBox && this.currentEditorBox.parentNode){
        this.currentEditorBox.parentNode.removeChild(this.currentEditorBox);
        this.currentEditorBox=false;
    }

    this.currentEditorBox=document.createElement("div");
    this.currentEditorBox.classList.add("editor_content_box");
    this.currentEditorBox.addEventListener('mousedown',function(event){
        event.preventDefault();//so it does not focus
    });
    let b=document.createElement("span");
        b.innerHTML="<i class='greppericon grepper_bold'></i>";
        b.addEventListener('click',function(){
            document.execCommand('bold');
            //el.textContent+=" ";//add a space to the end (if we don't have one alreay);

         //not sure about this
         //if(el.tagName=="P"){
         // if(el.textContent.slice(-1) != " "){
         //     console.log("adding it");
         //     el.appendChild( document.createTextNode(" "));
         // }
         //}

        }.bind(this));

    let i=document.createElement("span");
        i.innerHTML="<i class='greppericon grepper_italic'></i>";
        i.classList.add("italic");
        i.addEventListener('click',function(){
            document.execCommand('italic');
        }.bind(this));

    let c=document.createElement("span");
        c.innerHTML="<i class='greppericon grepper_code'></i>";
        //c.classList.add("italic");
        c.addEventListener('click',function(){

            document.execCommand('underline');
            //document.execCommand('hiliteColor',"#000000");
            //document.execCommand('StyleWithCSS','true','testing');
        }.bind(this));

    let l=document.createElement("span");
        l.innerHTML="<i class='greppericon grepper_linkify'></i>";
        if(el.tagName=="A"){
            l.classList.add('action_on');
        }
        l.addEventListener('mousedown',function(){
            //alert("shoging editor link");
           if(l.classList.contains("action_on")){
                    document.execCommand('unlink',false);
                    l.classList.remove("action_on");
           }else{
                this.showEditorLink(el,currentSelection);
           }
        }.bind(this));

    let divider=document.createElement("span");
        divider.classList.add("grepper_writeup_menu_divider");

    let downArrow=document.createElement("div");
        downArrow.classList.add("writeup_menu_arrow_down");

    let h3=document.createElement("span");
        h3.innerHTML="<i class='icon heading'></i>";
        if(el.tagName=="H3"){
            h3.classList.add('action_on');
        }
        h3.addEventListener('click',function(){
            if(h3.classList.contains("action_on")){
                    h3.classList.remove("action_on")
                    document.execCommand('formatBlock', true, 'p');
                    window.getSelection().focusNode.parentNode.setAttribute("tabindex","0");
            }else{

                    h3.classList.add("action_on")

                    if(this.isTitle(el)){
                        document.execCommand('formatBlock', true, '<h1>');
                        this.title=window.getSelection().focusNode.parentNode;
                        this.title.classList.add("focused");
                        this.title.setAttribute("id","writeup_title");
                    }else{
                        document.execCommand('formatBlock', true, '<h3>');
                    }

                    window.getSelection().focusNode.parentNode.setAttribute("tabindex","0");
            }
        }.bind(this));

    let h4=document.createElement("span");
        h4.innerHTML="<small><i class='icon heading'></i></small>";
      if(el.tagName=="H4"){
            h4.classList.add('action_on');
        }
        h4.addEventListener('click',function(){
            if(h4.classList.contains("action_on")){
                h4.classList.remove("action_on")
                document.execCommand('formatBlock', true, 'p');
                window.getSelection().focusNode.parentNode.setAttribute("tabindex","0");
            }else{
                h4.classList.add("action_on")
                document.execCommand('formatBlock', true, '<h4>');
                window.getSelection().focusNode.parentNode.setAttribute("tabindex","0");
            }
        }.bind(this));


    let h5=document.createElement("span");
        h5.innerHTML="<i class='icon sticky note outline'></i>";
      if(el.tagName=="H5"){
            h5.classList.add('action_on');
        }
        h5.addEventListener('click',function(){
            if(h5.classList.contains("action_on")){
                h5.classList.remove("action_on")
                document.execCommand('formatBlock', true, 'p');
                window.getSelection().focusNode.parentNode.setAttribute("tabindex","0");
            }else{
                h5.classList.add("action_on")
                document.execCommand('formatBlock', true, '<h5>');
                window.getSelection().focusNode.parentNode.setAttribute("tabindex","0");
            }
        }.bind(this));

    this.currentEditorBox.appendChild(b);
    this.currentEditorBox.appendChild(i);
    this.currentEditorBox.appendChild(c);
    this.currentEditorBox.appendChild(l);
    //this.currentEditorBox.appendChild(divider);
    //this.currentEditorBox.appendChild(h3);
    //this.currentEditorBox.appendChild(h4);
    //this.currentEditorBox.appendChild(divider);
    //this.currentEditorBox.appendChild(h5);
    this.currentEditorBox.appendChild(downArrow);

    scrollLeft = window.pageXOffset || document.documentElement.scrollLeft,
    scrollTop = window.pageYOffset || document.documentElement.scrollTop;

    let pos = currentSelection.getBoundingClientRect();

    this.currentEditorBox.style.top=(scrollTop+pos.top-55)+"px";
    this.currentEditorBox.style.left=(((pos.left+pos.right)/2)-82)+"px";

    document.body.appendChild(this.currentEditorBox);
}

grepperAnswerEditor.prototype.showEditorLink=function(el,currentSelection){


    let link_url=document.createElement('input');
        link_url.setAttribute("placeholder","Type or paste a link...");
        link_url.addEventListener("keyup",function(event){
            if (event.key === "Enter") {
                var selection = window.getSelection();
                    selection.removeAllRanges();
                    selection.addRange(currentSelection); //this is the old cloned range
                    document.execCommand('createLink',false,link_url.value);
                    this.removeEditorBoxIfNeeded(false);
                    selection.anchorNode.parentElement.target = '_blank';
                    selection.anchorNode.parentElement.setAttribute("rel","nofollow");
            }
        }.bind(this));

    let x=document.createElement("div");
        x.classList.add("delete_me_menu_icon");
        x.textContent="×";
        x.addEventListener('click',function(){
            x.parentNode.removeChild(x);
            link_url.parentNode.removeChild(link_url);
            this.currentEditorBox.classList.remove("hideicons");
        }.bind(this));

    this.currentEditorBox.classList.add("hideicons");
    this.currentEditorBox.appendChild(link_url);
    this.currentEditorBox.appendChild(x);


    link_url.focus();
}

grepperAnswerEditor.prototype.setupPasteListener=function(){
  this.advacedAnswerHolder.addEventListener("paste", function(event) {
       if(event.target.tagName==="TEXTAREA"){
          return;
       }

       let currentEl=this.getCurrentElement();
       event.preventDefault();
       event.stopPropagation();
      // let pastedData = event.clipboardData.getData('text/html');
        let pastedData2 = event.clipboardData.getData('text');

        let lines = pastedData2.split("\n");

        let newHTML="";
        if(lines.length){
            for(var i=0;i<lines.length;i++){
                if(!this.isEmptyOrSpaces(lines[i])){
                    newHTML+="<p tabindex='0'>"+lines[i]+" </p>";
                }
            }
        }else{
            newHTML=pastedData2;
        }

        newHTML=this.urlify(newHTML);

        //check if we are just pasting a link
      //if(pastedData2.length < 255 && pastedData2.length > 5 && this.isWebUrl(pastedData2)){
      //     newHTML='<a href="'+pastedData2+'" target="_blank">'+pastedData2+'</a>';
      //}else{
      //    //newHTML=pastedData2;
      //}

        document.execCommand("insertHTML", false, newHTML);
  }.bind(this));
}

grepperAnswerEditor.prototype.urlify=function(text) {
  var urlRegex = /(https?:\/\/[^\s]+)/g;
  return text.replace(urlRegex, function(url) {
    return '<a target="_blank" rel="nofollow" href="' + url + '">' + url + '</a>';
  })
  // or alternatively
  // return text.replace(urlRegex, '<a href="$1">$1</a>')
}

grepperAnswerEditor.prototype.isWebUrl=function(s) {
  s=s.trim();
  let url;
  try {
    url = new URL(s);
  } catch (_) {
    return false;
  }
  return url.protocol === "http:" || url.protocol === "https:";
}

grepperAnswerEditor.prototype.isEmptyOrSpaces=function(str){
    return str === null || str.match(/^ *$/) !== null;
}

   



