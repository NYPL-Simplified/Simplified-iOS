//
//  NYPLSAMLHelper.m
//  Simplified
//
//  Created by Ettore Pasquini on 10/21/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#import "SimplyE-Swift.h"

#import "NYPLSAMLHelper.h"


@implementation NYPLSAMLHelper

- (void)logIn
{
  // for this kind of authentication, we want the user to authenticate in a
  // built-in webview, as we need to access the cookies later on

  // get the url of IDP that user selected
  NSURL *idpURL = self.businessLogic.selectedIDP.url;

  NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:idpURL resolvingAgainstBaseURL:true];

  // add redirect uri param
  NSURLQueryItem *redirect_uri = [[NSURLQueryItem alloc] initWithName:@"redirect_uri" value:NYPLSettings.shared.authenticationUniversalLink.absoluteString];
  urlComponents.queryItems = [urlComponents.queryItems arrayByAddingObject:redirect_uri];
  NSURL *url = urlComponents.URL;

  void (^loginCompletionHandler)(NSURL * _Nonnull, NSArray<NSHTTPCookie *> * _Nonnull) = ^(NSURL * _Nonnull url, NSArray<NSHTTPCookie *> * _Nonnull cookies) {

    // when user login successfully, get cookies
    self.businessLogic.cookies = cookies;

    // process the last redirection url to get the oauth token
    [self.businessLogic handleRedirectURL:
     [NSNotification
      notificationWithName:NSNotification.NYPLAppDelegateDidReceiveCleverRedirectURL
      object:url
      userInfo:nil]];

    // and close the webview
    [self.businessLogic.uiDelegate dismissViewControllerAnimated:YES
                                                      completion:nil];
  };

  // create a model for webview authentication process
  NYPLCookiesWebViewModel *model = [[NYPLCookiesWebViewModel alloc]
                                    initWithCookies:@[]
                                    request:[[NSURLRequest alloc] initWithURL:url]
                                    loginCompletionHandler:loginCompletionHandler
                                    loginCancelHandler:nil
                                    bookFoundHandler:nil
                                    problemFoundHandler:nil
                                    autoPresentIfNeeded:NO];

  NYPLCookiesWebViewController *cookiesVC = [[NYPLCookiesWebViewController alloc]
                                             initWithModel:model];
  UINavigationController *navigationWrapper = [[UINavigationController alloc] initWithRootViewController:cookiesVC];
  [self.businessLogic.uiDelegate presentViewController:navigationWrapper
                                              animated:YES
                                            completion:nil];
}

@end
