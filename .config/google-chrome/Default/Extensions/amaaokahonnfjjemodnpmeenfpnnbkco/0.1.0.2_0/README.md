# Grepper - Chrome Plugin

## Installation

1. Clone repo locally: git clone https://github.com/TaylorHawkes/grepper.git
2. Open extension manager in chrome: chrome://extensions/
3. Cick "Load Unpack" and navigate to the grepper folder you just downloaded and click select.  

Your all set, you should see the Grepper plugin icon in top right of chrome. Try searching "javascript get first element of array" in google to see Grepper results. 

## Developer Notes

There are two main javascript files the plugin uses `content.js` and `content_page2.js`.  `content.js` is the scripts that loads when a user does a google search and it is used to fetch/add answers. `content_page2.js` loads on every other (non-google page), and it allows users to add answers. 


The plugin makes use of a grepper api. The primary endpoints it uses are:

For searching/getting answers: 
```https://www.codegrepper.com/api/get_answers_1.php?v=3&s=javascript+loop+array```

For saving answers: 
```https://www.grepper.com/api/save_answer.php```

For updating answers: 
```https://www.grepper.com/api/update_answer.php```

For submitting feedback on answers: 
```https://www.grepper.com/api/feedback.php```

**To release a new version of this plugin:**
1. Make your code changes. 
2. Bump the manifest version. 
3. Zip up the root folder.
4. Upload zipped file & submit in the chrome web store.


# Keyboard shortcuts
a - Create a new answer. <br/>
c - Copy/paste answer to your clipboard (cycles through answers).  <br/>

