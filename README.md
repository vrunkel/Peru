# Peru
Simple application to manage scientific literature 

As a long time user of Papers i couldn't find my way around in the latest version 4. I decided to do my own application and learning SwiftUI better that way. Currently it is not finished yet. Focus lies on the general UI and import of Endnote XML files. This import is adjusted in such a way that if you place the exported xml from Papers3 in your Papers 3 library folder, the pdf files for each article are imported and copied to Peru's support folder. Note that an authorization to the main folder (your Papers library folder) is necessary to gain sandbox entitlements for the copying of files.

The UI is rather straight forward. It is based on a table showing the literature (articles, books, ...) available in the database. Left side bar allows direrct selection of keywords (if available) and the creation and use of collections. A collection for example is useful if you want to group literature cited in a work you publish. On the right is a display of article/book details as shown in the screenshot.

![Main UI with Article in View mode](/images/MainScreenWithArticleSelected.png?raw=true "Main UI with Article in View mode")

If the edit mode is activated entries for the article (single selection only) can be edited.

![Main UI with Article in Edit mode](/images/MainScreenWithArticleSelectedAndEditMode.png?raw=true "Main UI with Article in Edit mode")
