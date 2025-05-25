# bookxpert-ios-test
# Bookxpert iOS Test App

## Summary of implementation details:

- The App is about showing google based user authentication, offline data management, local
notifications,setting the image from camera / photo library and aPDF viewer.

- Functionality:
    1. User Authentication:
        -> Google Sign-In using Firebase Authentication.
        -> Save user details in Core Data

    2. (PDF Viewer):
        -> Show downloaded PDF document in PDF Viewer
        
    3. Profile photo:
        -> Implement an option to capture an image using the camera.
        -> Allow users to pick an image from the gallery.
       
    4. Mobile catalogue with offline mode using Core Data:
        -> Fetch the list of data from the backend.
        -> Store the details retrieved from the API into a Core Data.
        -> Provide Update and Delete of Items for Stored Data
        -> Error Handling
        -> Validations

    5. Local Notification:
        -> When Delete an Item (items getting from API), Send a local notification
        -> Notification contains Deleted Items details
        -> Allow users to Enable/Disable notifications

- Developed the App using Xcode 16.2 and Swift 6.

- FireBase & GoogleSignIn third party libraries are used.

- Main focus on implementing right architecture, design patterns and performance of the App.

- Followed Modular architecture to make the code reusable and maintainable.

- Implemented UI modules using SwiftUI.

- Followed MVVM-C based clean architecture- Model,View, ViewModel, Coordinator, Repository & Service 
  
- Followed Coordinator pattern for navigation.

- Used Protocol Oriented Progrmming approach wherever it is possible

- Used dependency injection across the App to facilitate the unit testing of the classes.

- Implemented unit tests using XCTest framework and Mock Objects.

- Used NSURLSession for network operations.

- Used Switt Codable for parsing JSON data.

- Used Combine framework for reactive programming.

- Used Swift Concurrency for async operations.

