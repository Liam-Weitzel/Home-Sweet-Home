chrome.runtime.onInstalled.addListener(function (details) {
  if (details.reason !== 'install' && details.reason !== 'update') {
    return;
  }
  chrome.storage.local.get('optionsMigrated', function (items) {
    if (items.optionsMigrated) {
      return;
    }
    console.log('Migrating options from localStorage');
    var itemsToSave = {};
    var ver = '1.4.6';
    var autoOpen = localStorage.getItem('auto_open');
    if (autoOpen === 'true') {
      itemsToSave['auto_open'] = { value: true, version: ver };
    }
    var hidePackageFrame = localStorage.getItem('hide_package_frame');
    if (hidePackageFrame === 'false') {
      itemsToSave['hide_package_frame'] = { value: false, version: ver };
    }
    var packageMenu = localStorage.getItem('package_menu');
    var packageMenuDefault =
      '@1:search(koders) -> http://www.koders.com/?s=##PACKAGE_NAME##\n' +
      '@2:search(Docjar) -> http://www.docjar.com/s.jsp?q=##PACKAGE_NAME##';
    if (packageMenu && packageMenu !== packageMenuDefault) {
      itemsToSave['package_menu'] = { value: packageMenu, version: ver };
    }
    var classMenu = localStorage.getItem('class_menu');
    var classMenuDefault =
      '@1:search(koders) -> http://www.koders.com/' +
      '?s=##PACKAGE_NAME##+##CLASS_NAME##+##MEMBER_NAME##\n' +
      '@2:search(Docjar) -> http://www.docjar.com/s.jsp?q=##CLASS_NAME##\n' +
      '@3:source(Docjar) -> http://www.docjar.com/html/api/' +
      '##PACKAGE_PATH##/##CLASS_NAME##.java.html';
    if (classMenu && classMenu !== classMenuDefault) {
      itemsToSave['class_menu'] = { value: classMenu, version: ver };
    }
    chrome.storage.sync.set(itemsToSave);
    console.log(itemsToSave);
    chrome.storage.local.set({ optionsMigrated: true });
  });
});

function hideAllPackagesFrame(sender) {
  chrome.webNavigation.getFrame(
    {
      tabId: sender.tab.id,
      frameId: sender.frameId,
    },
    function (details) {
      chrome.scripting.executeScript({
        target: { tabId: sender.tab.id, frameIds: [details.parentFrameId] },
        func: Frames.hideAllPackagesFrame,
      });
    }
  );
}

chrome.runtime.onMessage.addListener(function (request, sender, sendResponse) {
  if (request.operation === 'open-options-page') {
    chrome.runtime.openOptionsPage();
    sendResponse();
    return false;
  }
  if (request.operation === 'hide-allpackages-frame') {
    hideAllPackagesFrame(sender);
    sendResponse();
    return false;
  }
});

chrome.commands.onCommand.addListener(function (command) {
  chrome.tabs.query({ active: true, currentWindow: true }, function (tabs) {
    tabs.forEach(function (tab) {
      chrome.tabs.sendMessage(tab.id, command);
    });
  });
});

/*
 * ----------------------------------------------------------------------------
 * Frames
 * ----------------------------------------------------------------------------
 */

/**
 * @class Provides functions to interact with other frames.
 */
Frames = {};

/**
 * Hide the packages frame. If the packages frame does not exist, calling this
 * function will have no effect.
 *
 * @param {Document} [parentDocument] The document containing the Javadoc frames or iframes.
 */
Frames.hideAllPackagesFrame = function (parentDocument) {
  var framesets = (parentDocument || document).getElementsByTagName('frameset');
  if (framesets.length > 1) {
    // Javadoc created with Java 8 or earlier
    var frameset = framesets[1];
    var framesetChildren = frameset.children;
    if (
      framesetChildren.length &&
      framesetChildren[0].name === 'packageListFrame'
    ) {
      frameset.setAttribute('rows', '0,*');
      frameset.setAttribute('border', '0');
      frameset.setAttribute('frameborder', '0');
      frameset.setAttribute('framespacing', '0');
    }
  } else {
    // Javadoc created with Java 9
    var divs = parentDocument.getElementsByTagName('div');
    for (var i = 0; i < divs.length; i++) {
      var div = divs[i];
      if (div.className === 'leftTop') {
        div.style.display = 'none';
      }
      if (div.className === 'leftBottom') {
        div.style.height = '100%';
      }
    }
  }
};

/**
 * Open the given URL in the summary frame. If the summary frame is not
 * displayed, the URL will be opened in a new tab or window.
 * @param {string} url The URL to open.
 */
Frames.openLinkInSummaryFrameOrNewTab = function (url) {
  if (window.top === window) {
    Frames.openLinkInNewTab(url);
  } else {
    window.open(url, 'classFrame');
  }
};

/**
 * Open the given URL in a new tab.
 * @param {string} url The URL to open.
 */
Frames.openLinkInNewTab = function (url) {
  window.open(url);
};
