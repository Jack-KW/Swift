In an app, I need to scan text from an arbitrary part of any image like what the VNDocumentCameraViewController can do. However, the VNDocumentCameraViewController's auto text detection mechanism works so fast that is hard to be controlled by the user or developer. So I built this manual image crop view.

It is a combination of an image view, an overlay quadrilateral control, and a button to trigger the cropping.

The result looks like this:

<img src="https://github.com/Jack-KW/Swift/assets/62434637/03d87f6c-bc84-4778-8576-d9c4cc040896" width="500" />

