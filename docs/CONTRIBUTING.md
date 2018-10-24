# dSIPRouter Contribution Guide

First, we appreciate any contribution you can make to the product.  We need three types of contributions:

1. Monatary Donations (Keeps developers happy)
2. Documentation assistence
3. Testing
4. Code Level (Feature Enhancements and Patch/BUG fixes)

## Code Level Contributions

1. Create a branch for your feature enhancement and/or patch/bug.

If you are working on an issue reported via Github then add the issue number to the end of the branch name. In the following example we are working on adding Domain Management to dSIPRouter, which is defined as issue [84](https://github.com/dOpensource/dsiprouter/issues/84) on the issue tracker.  

```
git checkout -b domain_management_84
```

2. Implement your feature or enhancement

3. Test your feature or enhancement and validate that it doesn't break the build.  The best way to validate this is to perform a full install (we will have a full Continous Integration(CI) platform very soon)

4. Commit and make sure your commit message comtains a reference to the issue if you are working on one.  For example, the commit message for Domain Management (Issue 84):

```
Added support for creating domains.  It contains these features:

- Ability to display static and dynamic domains via the UI
- Can add/update/modifu a domain via the GUI
- The logic to reload Dynamic domains has been adjusted to account for 
  the ability to add domains statically
  
  Issue #84
```

5. Push your commit
