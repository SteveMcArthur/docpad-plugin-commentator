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

## License 

(The MIT License)

Copyright (c) 2014 Steve McArthur &lt;contact@stevemcarthur.co.uk&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



