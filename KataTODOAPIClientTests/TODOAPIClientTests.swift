//
//  TODOAPIClientTests.swift
//  KataTODOAPIClient
//
//  Created by Pedro Vicente Gomez on 12/02/16.
//  Copyright © 2016 Karumi. All rights reserved.
//

import Foundation
import Nocilla
import Nimble
import XCTest
import Result
@testable import KataTODOAPIClient

class TODOAPIClientTests: NocillaTestCase {

    fileprivate let apiClient = TODOAPIClient()
    fileprivate let anyTask = TaskDTO(userId: "1", id: "2", title: "Finish this kata", completed: true)
    fileprivate let STATUS_INTERNAL_ERROR = 500
    fileprivate let STATUS_SUCCESS = 200
    fileprivate let STATUS_NOT_FOUND = 404

    // MARK: todos/
    
    func testSendsContentTypeHeader() {
        _ = stubRequest("GET", "http://jsonplaceholder.typicode.com/todos")
            .withHeaders(["Content-Type": "application/json", "Accept": "application/json"])?
            .andReturn(200)

        var result: Result<[TaskDTO], TODOAPIClientError>?
        apiClient.getAllTasks { response in
            result = response
        }

        expect(result).toEventuallyNot(beNil())
    }

    func testParsesTasksProperlyGettingAllTheTasks() {
        _ = stubRequest("GET", "http://jsonplaceholder.typicode.com/todos")
            .andReturn(200)?
            .withJsonBody(fromJsonFile("getTasksResponse"))

        var result: Result<[TaskDTO], TODOAPIClientError>?
        apiClient.getAllTasks { response in
            result = response
        }

        expect(result?.value?.count).toEventually(equal(200))
        assertTaskContainsExpectedValues(task: (result?.value?[0])!)
    }

    func testReturnsNetworkErrorIfThereIsNoConnectionGettingAllTasks() {
        _ = stubRequest("GET", "http://jsonplaceholder.typicode.com/todos")
            .andFailWithError(NSError.networkError())

        var result: Result<[TaskDTO], TODOAPIClientError>?
        apiClient.getAllTasks { response in
            result = response
        }

        expect(result?.error).toEventually(equal(TODOAPIClientError.networkError))
    }
    
    //1. spec: GET todos/ retornar 500
    func test_given_server_500_when_get_tasks_then_match_500() {
        _ = stubRequest("GET", "http://jsonplaceholder.typicode.com/todos")
            .withHeaders(["Content-Type": "application/json", "Accept": "application/json"])?
            .andReturn(STATUS_INTERNAL_ERROR)
        
        var result: Result<[TaskDTO], TODOAPIClientError>?
        apiClient.getAllTasks { response in
            result = response
        }
        
        expect(result?.error).toEventually(equal(TODOAPIClientError.unknownError(code: STATUS_INTERNAL_ERROR)))
    }
    
    //2. spec: GET todos/ malformed JSON
    func test_given_server_malformed_response_when_get_tasks_then_match_error() {
        _ = stubRequest("GET", "http://jsonplaceholder.typicode.com/todos")
            .withHeaders(["Content-Type": "application/json", "Accept": "application/json"])?
            .andReturn(STATUS_SUCCESS)?
            .withJsonBody(fromJsonFile("malformed_json"))
        
        var result: Result<[TaskDTO], TODOAPIClientError>?
        apiClient.getAllTasks { response in
            result = response
        }
        
        expect(result?.error).toEventually(equal(TODOAPIClientError.networkError))
    }
    
    //4. spec: GET todos/ timeout
    func test_given_timeout_when_get_tasks_then_match_error() {
        _ = stubRequest("GET", "http://jsonplaceholder.typicode.com/todos")
            .andFailWithError(NSError.timeoutError())
        
        var result: Result<[TaskDTO], TODOAPIClientError>?
        apiClient.getAllTasks { response in
            result = response
        }
        
        expect(result?.error).toEventually(equal(TODOAPIClientError.networkError))
    }
    
    //MARK: todo/:id
    
    //200+path: implicito si responde+headers: implicito si response
    func test_given_server_task_when_get_task_by_id_then_match_parsing() {
        _ = stubRequest("GET", "http://jsonplaceholder.typicode.com/todos/1")
            .withHeaders(["Content-Type": "application/json", "Accept": "application/json"])?
            .andReturn(STATUS_SUCCESS)?
            .withJsonBody(fromJsonFile("getTaskByIdResponse"))
        
        var result: Result<TaskDTO, TODOAPIClientError>?
        apiClient.getTaskById("1") { (response) in
            result = response
        }

        expect(result?.value).toEventuallyNot(beNil())
        assertTaskContainsExpectedValues(task: result!.value!)
    }
    
    //404
    func test_given_server_not_existing_task_when_get_task_by_id_then_match_not_found() {
        _ = stubRequest("GET", "http://jsonplaceholder.typicode.com/todos/1")
            .withHeaders(["Content-Type": "application/json", "Accept": "application/json"])?
            .andReturn(STATUS_NOT_FOUND)
        
        var result: Result<TaskDTO, TODOAPIClientError>?
        apiClient.getTaskById("1") { (response) in
            result = response
        }
        
        expect(result?.error).toEventually(equal(TODOAPIClientError.itemNotFound))
    }
    
    //500
    func test_given_server_internal_error_when_get_task_by_id_then_match_error() {
        _ = stubRequest("GET", "http://jsonplaceholder.typicode.com/todos/1")
            .withHeaders(["Content-Type": "application/json", "Accept": "application/json"])?
            .andReturn(500)
        
        var result: Result<TaskDTO, TODOAPIClientError>?
        apiClient.getTaskById("1") { (response) in
            result = response
        }
        
        expect(result?.error).toEventually(equal(TODOAPIClientError.unknownError(code: 500)))
    }
    
    //timeout
    //malformed json
    
    // MARK: POST todos
    
    //201+headers+body(upload)
    func test_given_server_create_post_given_post_then_match_creation(){
        _ = stubRequest("POST", "http://jsonplaceholder.typicode.com/todos")
            .withHeaders(["Content-Type": "application/json", "Accept": "application/json", "Content-Length": "59"])?
            .withJsonBody("{\"completed\":false,\"userId\":\"1\",\"title\":\"Finish this kata\"}")?
            .andReturn(201)?
            .withJsonBody(fromJsonFile("addTaskToUserRequest"))
        
        var result: Result<TaskDTO, TODOAPIClientError>?
        apiClient.addTaskToUser("1", title: "Finish this kata", completed: false) { (response) in
            result = response
        }
        
        expect(result?.value?.completed).toEventually(equal(false))
        expect(result?.value?.userId).toEventually(equal("1"))
        expect(result?.value?.title).toEventually(equal("Finish this kata"))
    }
    
    //40x
    //id?
    //VERBO: implicito
    //parsing
    //path
    //500
    //timeout
    //malformed json
    
    // MARK: DELETE todos/:id
    //verbo+200+path+headers
    func test_given_server_delete_given_delete_then_match_deletion() {
        _ = stubRequest("DELETE", "http://jsonplaceholder.typicode.com/todos/1")
            .withHeaders(["Content-Type": "application/json", "Accept": "application/json"])?
            .andReturn(200)
        
        var result: Result<Void, TODOAPIClientError>?
        apiClient.deleteTaskById("1") { (response) in
            result = response
        }
        
        expect(result?.value).toEventuallyNot(beNil())
        expect(result?.error).toEventually(beNil())
    }
    
    //404
    //500
    //timeout
    //malformed json
    
    // MARK: put todos/:id
    //200
    func test_given_server_put_given_update_then_match_update() {
        _ = stubRequest("PUT", "http://jsonplaceholder.typicode.com/todos/1")
            .withHeaders(["Content-Type": "application/json", "Accept": "application/json", "Content-Length": "67"])?
            .withJsonBody(fromJsonFile("updateTaskRequest"))?
            .andReturn(200)?
            .withJsonBody(fromJsonFile("updateTaskResponse"))
        
        var result: Result<TaskDTO, TODOAPIClientError>?
        let data = TaskDTO(userId: "1", id: "2", title: "Finish this kata", completed: true)
        apiClient.updateTask(data) { (response) in
            result = response
        }
        
        expect(result?.value?.completed).toEventually(equal(data.completed))
        expect(result?.value?.id).toEventually(equal(data.id))
        expect(result?.value?.userId).toEventually(equal(data.userId))
        expect(result?.value?.title).toEventually(equal(data.title))
    }
    
    //404
    //500
    //timeout
    //malformed json

    // MARK: private
    private func assertTaskContainsExpectedValues(task: TaskDTO) {
        expect(task.id).to(equal("1"))
        expect(task.userId).to(equal("1"))
        expect(task.title).to(equal("delectus aut autem"))
        expect(task.completed).to(beFalse())
    }
}
