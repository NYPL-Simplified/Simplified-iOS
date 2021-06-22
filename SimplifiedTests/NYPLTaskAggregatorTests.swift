//
//  NYPLTaskAggregatorTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-06-22.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLTaskAggregatorTests: XCTestCase {
  
  func testAggregatorShouldNotExecuteMoreTasksAfterFailing() {
    let continueExpectation = self.expectation(
      description: "Aggregator should not continue upon experiencing failure")
    let failureExpectation = self.expectation(
      description: "Aggregator should fail upon receiving failure")
    
    continueExpectation.isInverted = true
    
    let sut = NYPLAxisTaskAggregator()
    
    let passingTask1 = NYPLAxisTask() { $0.succeeded() }
    let failingTask = NYPLAxisTask() { $0.failed(with: .invalidLicense) }
    let passingTask2 = NYPLAxisTask() {
      continueExpectation.fulfill()
      $0.succeeded()
    }
    
    sut
      .addTasks([passingTask1, failingTask, passingTask2])
      .run()
      .onCompletion { (result) in
        switch result {
        case .success:
          XCTFail()
        case .failure(let error):
          switch error {
          case .invalidLicense:
            failureExpectation.fulfill()
          default:
            XCTFail()
          }
          
        }
      }
    
    waitForExpectations(timeout: 3, handler: nil)
  }
  
  func testAggregatorShouldSucceedWhenAllTasksAreCompleted() {
    let continueExpectation = self.expectation(
      description: "Aggregator should continue if no tasks fail")
    let successExpectation = self.expectation(
      description: "Aggregator should succeed upon finishing all tasks")
    
    let sut = NYPLAxisTaskAggregator()
    
    let passingTask1 = NYPLAxisTask() { $0.succeeded() }
    let passingTask2 = NYPLAxisTask() { $0.succeeded() }
    let passingTask3 = NYPLAxisTask() {
      continueExpectation.fulfill()
      $0.succeeded()
    }
    
    sut
      .addTasks([passingTask1, passingTask2, passingTask3])
      .run()
      .onCompletion { (result) in
        switch result {
        case .success:
          successExpectation.fulfill()
        case .failure:
            XCTFail()
        }
      }
    
    waitForExpectations(timeout: 3, handler: nil)
  }
  
  func testAggregatorShouldNotExecuteTasksAfterGettingCancelled() {
    let continueExpectation = self.expectation(
      description: "Aggregator should not continue upon getting cancelled")
    let cancelExpectation = self.expectation(
      description: "Aggregator should fail upon getting cancelled")
    
    continueExpectation.isInverted = true
    
    let sut = NYPLAxisTaskAggregator()
    
    let passingTask1 = NYPLAxisTask() {
      sut.cancelAllTasks(with: .userCancelledDownload)
      $0.succeeded()
    }
    
    let passingTask2 = NYPLAxisTask() {
      continueExpectation.fulfill()
      $0.succeeded()
    }
    
    let passingTask3 = NYPLAxisTask() {
      continueExpectation.fulfill()
      $0.succeeded()
    }
    
    sut
      .addTasks([passingTask1, passingTask2, passingTask3])
      .run()
      .onCompletion { (result) in
        switch result {
        case .success:
          XCTFail()
        case .failure(let error):
          switch error {
          case .userCancelledDownload:
            cancelExpectation.fulfill()
          default:
            XCTFail()
          }
        }
      }
    
    waitForExpectations(timeout: 3, handler: nil)
  }
  
  func testAggregatorShouldExecuteTasksInTheOrderTheyWereAdded() {
    let orderExpectation = self.expectation(
      description: "Aggregator should execute tasks in the order they were added")
    
    let sut = NYPLAxisTaskAggregator()
    
    var value = ""
    
    let passingTask1 = NYPLAxisTask() { task in
      DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
        value = value + "1"
        task.succeeded()
      }
    }
    
    let passingTask2 = NYPLAxisTask() {
      value = value + "2"
      $0.succeeded()
    }
    
    let passingTask3 = NYPLAxisTask() {
      value = value + "3"
      $0.succeeded()
    }
    
    sut
      .addTasks([passingTask1, passingTask2, passingTask3])
      .run()
      .onCompletion { (result) in
        switch result {
        case .success:
          if value == "123" {
            orderExpectation.fulfill()
          }
        case .failure:
            XCTFail()
        }
      }
    
    waitForExpectations(timeout: 3, handler: nil)
  }
  
}
