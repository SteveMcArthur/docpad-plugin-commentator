Comments Plugin For [DocPad](https://docpad.org)
=========================

Post commenting system for docpad. Uses ajax to post comments back to the server and save them as markdown. Allows nested comments - ie comments associated with other comments on the page and displayed directly underneath and indented. Owes a lot to the [docpad-native-comments](https://github.com/docpad/docpad-plugin-nativecomments) plugin. Main difference is that it uses ajax posting to the server and client side updating of the comment page with the newly posted comment. Comment markup is also stored in a seperate ".eco" file which can be substituted by the user as one of the config options. The ".eco" file is also rendered internally, so there is no need to use the double ".eco" extension in the target document.

## Install

1. To install the Plugin, navigate to the root of your docpad project and run the following command

  ```
 npm install docpad-plugin-commentator
  ```

1. In the document that you want to include comments on, place the following line of code

  ```
  <%- @getCommentsBlock() %>
  ```

![Screenshot](https://raw.githubusercontent.com/SteveMcArthur/docpad-plugin-commentator/master/screen-shot.jpg)

## History
[Discover the change history by heading on over to the `HISTORY.md` file.](https://github.com/SteveMcArthur/docpad-plugin-commentator/blob/master/HISTORY.md#)
