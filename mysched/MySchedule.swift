//
//  MySchedule.swift
//  mysched
//
//  Created by Ryan Sheridan on 07/03/2023.
//

import SwiftSoup
import Foundation

class MySchedule {
    private var gUserID: Int = 0
    private var gPass: String = ""
    
    private var gPersonID: String = ""
    private var gStoreNumber: String = ""
    
    private var gStartWeek: Int?
    private var gReflexisToken: String?
    
    private let scheduleDomain = "https://mcduk.reflexisinc.co.uk"
    private let homePage = "/kernel/views/authenticate/W/MCDUK.view"
    private let userLogin = "/kernel/views/validateuserlogin.view"
    private let empJspPage = "/RWS4/ess/ess_emp_schedule.jsp?authToken="
    
    private var shiftsJSONPage: String = "null"
    private var gSetCookie: String?
    private var gHomePage: String?
    private var gAuthToken: String?
    
    private var gShiftsJSON: String = ""
    
    private struct Shift: Codable {
        let startDate: Int
        let startTime: Int
        let duration: Int

        init(fromInt value: Int) {
            self.startDate = value
            self.startTime = value
            self.duration = value
        }

        init(startDate: Int, startTime: Int, duration: Int) {
            self.startDate = startDate
            self.startTime = startTime
            self.duration = duration
        }
    }
    
    private var shifts: [Shift] = []
    
    public func setUserAndPass(user: Int, pass: String) -> () {
        self.gUserID = user
        self.gPass = pass
    }
    
    private func get(url: String) -> ([String: String]?, String?) {
        guard let urlObj = URL(string: url) else {
            print("Invalid URL")
            return (nil, nil)
        }
        
        var request = URLRequest(url: urlObj)
        request.httpMethod = "GET"
        
        var responseHeaders: [String: String]?
        var responseBody: String?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            defer { semaphore.signal() }
            
            if let error = error {
                print("Request error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                responseHeaders = httpResponse.allHeaderFields as? [String: String]
            }
            
            if let data = data, let body = String(data: data, encoding: .utf8) {
                responseBody = body
            }
        }
        
        task.resume()
        semaphore.wait()
        
        return (responseHeaders, responseBody)
    }
    
    private func getAuthTokenHTML(urlString: String, parameters: String) -> String? {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var responseString: String?
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer {
                semaphore.signal()
            }
            
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "Unknown error")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Status code: \(httpResponse.statusCode)")
            }
            
            responseString = String(data: data, encoding: .utf8)
        }
        
        task.resume()
        
        semaphore.wait()
        
        return responseString
    }
    
    
    private func getReflexisToken(fromCookie: String) -> String {
        var token = fromCookie.substring(fromIndex: 24)
        token = token.substring(toIndex: token.length - 43 - 22)
        return token
    }
    
    private func getFormToken(html: String) -> String {
        do {
            let doc = try SwiftSoup.parse(html)
            let formElement: Element = try doc.getElementById("formToken")!
            let formElementValue: String = try formElement.attr("value")
            
            return formElementValue
        } catch {
            print("Error: \(error)")
        }
        
        return "0"
    }
    
    private func getInputId(type: Int, html: String) -> String {
        var inputId: String = "err"
        do {
            let doc = try SwiftSoup.parse(html)
            if type != 0 {
                let inputUserIdElement = try doc.getElementsByAttribute("placeholder")
                inputId = try inputUserIdElement[0].attr("id")
            } else {
                let passIdElement = try doc.getElementsByAttribute("placeholder")
                inputId = try passIdElement[1].attr("id")
            }
        } catch {
            print("Error: \(error)")
        }
        return inputId
    }
    
    public func getUserID() -> Int {
        return gUserID
    }
    
    public func getPass() -> String {
        return gPass.base64Encoded!
    }
    
    private func getAuthToken(html: String) -> String {
        do {
            let doc = try SwiftSoup.parse(html)
            let inputElementsWithName = try doc.getElementsByAttribute("name")
            for i in 0..<inputElementsWithName.count {
                let inputName = try inputElementsWithName[i].attr("name")
                if inputName == "authToken" {
                    let authToken = try inputElementsWithName[i].attr("value")
                    return authToken
                }
            }
        } catch {
            print("Error: \(error)")
        }
        return "none"
    }
    
    public func getDateText() -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyyMMdd"

        guard let date = inputFormatter.date(from: String(gStartWeek!)) else {
            return "Invalid Date"
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d'th' 'of' MMM yyyy"
        
        let dateString = outputFormatter.string(from: date)

        // Replace 'th' with appropriate ordinal suffix
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let ordinalSuffix = getOrdinalSuffix(day: day)
        let finalDateString = dateString.replacingOccurrences(of: "th", with: ordinalSuffix)

        return finalDateString
    }
    
    public func getDateText(date: Int) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyyMMdd"

        guard let date = inputFormatter.date(from: String(date)) else {
            return "Invalid Date"
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d'th' 'of' MMM yyyy"
        
        let dateString = outputFormatter.string(from: date)

        // Replace 'th' with appropriate ordinal suffix
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let ordinalSuffix = getOrdinalSuffix(day: day)
        let finalDateString = dateString.replacingOccurrences(of: "th", with: ordinalSuffix)

        return finalDateString
    }



    private func getOrdinalSuffix(day: Int) -> String {
        let mod10 = day % 10
        let mod100 = day % 100
        
        if mod10 == 1 && mod100 != 11 {
            return "st"
        } else if mod10 == 2 && mod100 != 12 {
            return "nd"
        } else if mod10 == 3 && mod100 != 13 {
            return "rd"
        }
        
        return "th"
    }

    
    public func setNewDate(date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: date)
        gStartWeek = Int(dateString) ?? 0
    }
    
    public func goBackOneWeek() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        if let date = dateFormatter.date(from: String(gStartWeek!)) {
            let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: date)
            setNewDate(date: oneWeekAgo!)
        }
    }

    public func goForwardOneWeek() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        if let date = dateFormatter.date(from: String(gStartWeek!)) {
            let oneWeekLater = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: date)
            setNewDate(date: oneWeekLater!)
        }
    }
    
    private func getWeekStart(for date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // set the weekday to the first day of the week
        
        guard let weekStartDate = calendar.date(from: components) else {
            fatalError("Failed to get the start of the week for \(date)")
        }
        
        return weekStartDate
    }
    
    private func getEmpJsp(xReflexisFormToken: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let urlString = "https://mcduk.reflexisinc.co.uk/RWS4/ess/ess_emp_schedule.jsp?authToken=\(gAuthToken!)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.addValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
        request.addValue("mcduk.reflexisinc.co.uk", forHTTPHeaderField: "Alt-Used")
        request.addValue("https://mcduk.reflexisinc.co.uk/MYWORK/service/redirect/redirectUrl", forHTTPHeaderField: "Referer")
        request.addValue("X-reflexis-form-token-X=\(xReflexisFormToken)", forHTTPHeaderField: "Cookie")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            completionHandler(data, response, error)
        }
        task.resume()
    }
    
    private func getStoreNumberAndPersonID() -> (storeNumber: String, personId: String)? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: (storeNumber: String, personId: String)?

        getEmpJsp(xReflexisFormToken: gReflexisToken!) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                semaphore.signal()
                return
            }

            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print("Error: No data or invalid response")
                semaphore.signal()
                return
            }

            if let htmlString = String(data: data, encoding: .utf8) {
                let storeNumberPattern = "var unitDetailsMap = \\{\"(\\d+)\""
                let personIdPattern = "\"personId\":(\\d+)"

                do {
                    let storeNumberRegex = try NSRegularExpression(pattern: storeNumberPattern, options: [])
                    let personIdRegex = try NSRegularExpression(pattern: personIdPattern, options: [])

                    let storeNumberMatches = storeNumberRegex.matches(in: htmlString, options: [], range: NSRange(htmlString.startIndex..., in: htmlString))
                    let personIdMatches = personIdRegex.matches(in: htmlString, options: [], range: NSRange(htmlString.startIndex..., in: htmlString))

                    if let storeNumberMatch = storeNumberMatches.first, let storeNumberRange = Range(storeNumberMatch.range(at: 1), in: htmlString),
                       let personIdMatch = personIdMatches.first, let personIdRange = Range(personIdMatch.range(at: 1), in: htmlString) {
                        let storeNumber = String(htmlString[storeNumberRange])
                        let personId = String(htmlString[personIdRange])
                        result = (storeNumber: storeNumber, personId: personId)
                    } else {
                        print("Error: Store number or person ID not found")
                    }
                } catch {
                    print("Error: Invalid regular expression")
                }
            } else {
                print("Error: Unable to convert data to string")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    
    private func getShiftsJSON() -> Bool {
        
        if gAuthToken == nil {
            setNewDate(date: getWeekStart(for: Date()))
            
            print("gAuthToken is nil, this should be the first run?")
            /*
             get our headers and our body, with this information we will gather our xreflexistoken
             our formToken, userId input id and pass inputId
             */
            let (headers, body) = get(url: scheduleDomain+homePage)
            
            if let headers = headers {
                gSetCookie = headers["Set-Cookie"]
            } else {
                print("No headers returned")
            }
            
            if let body = body {
                print("Got response body")
                gHomePage = body
            } else {
                print("No response body returned")
            }
            
            let reflexisToken = getReflexisToken(fromCookie: gSetCookie!)
            gReflexisToken = reflexisToken
            print("X-reflexis-form-token-X: \(reflexisToken)")
            
            let formToken = getFormToken(html: gHomePage!)
            print("our formToken: \(formToken)")
            
            let inputIdUser = getInputId(type: 1, html: gHomePage!)
            let inputIdPass = getInputId(type: 0, html: gHomePage!)
            print("userinputid: \(inputIdUser)\npassinputid: \(inputIdPass)")
            
            let params = "selectedLocale=en_GB&hidden=&formToken=\(formToken)&showUserQuestions=N&domainId=MCDUK&deviceType=WEB&\(inputIdUser)=\(gUserID)&\(inputIdPass)=\(gPass)&secureFormFields=true"
            
            if let authTokenHTML = getAuthTokenHTML(urlString: scheduleDomain+userLogin, parameters: params) {
                if authTokenHTML.contains("authToken") {
                    print("doc contains the authToken, woohoo!")
                    gAuthToken = getAuthToken(html: authTokenHTML)
                } else {
                    print("Error: this document does not contain the authToken, login details correct?")
                    print("\tif your sure the login details are correct, make sure the input field ids are correct too")
                }
            } else {
                print("Error: getAuthTokenHTML return is nil i think")
            }
            
        } else {
            print("not the first run, getting next shifts")
        }
        
        let startWeek = gStartWeek!
        let endWeek = startWeek + 6
        
        // 00807084 ballymun store
        guard let _ = gAuthToken else {
                return false
        }
        if gStoreNumber == "" {
            if let result = getStoreNumberAndPersonID() {
                gStoreNumber = result.storeNumber
                gPersonID = result.personId
                
                shiftsJSONPage = "/RWS4/controller/ess/shift/advanced/associatepublishedshifts/\(gStoreNumber)/\(gPersonID)/\(startWeek)/\(endWeek)/0/01425.json?authToken=\(gAuthToken!)"
                
                let shiftsJSON = get(url: scheduleDomain+shiftsJSONPage).1
                
                gShiftsJSON = shiftsJSON!
            } else {
                print("Error: Unable to retrieve store number and person ID")
            }
        } else {
            shiftsJSONPage = "/RWS4/controller/ess/shift/advanced/associatepublishedshifts/\(gStoreNumber)/\(gPersonID)/\(startWeek)/\(endWeek)/0/01425.json?authToken=\(gAuthToken!)"
            
            let shiftsJSON = get(url: scheduleDomain+shiftsJSONPage).1
            
            gShiftsJSON = shiftsJSON!
        }
        return true
    }
    
    public func getPersonInfo() -> [String]? {
        var personInfo: [String]?
        
        getEmpJsp(xReflexisFormToken: gReflexisToken!) { [self] (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                personInfo = nil
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print("Error: No data or invalid response")
                personInfo = nil
                return
            }
            
            if let htmlString = String(data: data, encoding: .utf8) {
                // Search for the loggedAssociateDetails variable in the HTML string
                let loggedAssociateDetailsPattern = #"var loggedAssociateDetails = (\{.*?\});"#
                
                do {
                    let regex = try NSRegularExpression(pattern: loggedAssociateDetailsPattern, options: [])
                    let matches = regex.matches(in: htmlString, options: [], range: NSRange(htmlString.startIndex..., in: htmlString))
                    
                    if let match = matches.first, let range = Range(match.range(at: 1), in: htmlString) {
                        let loggedAssociateDetailsString = String(htmlString[range])
                        if let data = loggedAssociateDetailsString.data(using: .utf8),
                           let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            let storeNumber = jsonObject["homeUnitId"] as? String ?? ""
                            let firstName = jsonObject["firstName"] as? String ?? ""
                            let lastName = jsonObject["lastName"] as? String ?? ""
                            let dateOfHire = jsonObject["dateOfHire"] as? Int ?? 0
                            let jobTitle = jsonObject["jobTitle"] as? String ?? ""
                            let baseRate = jsonObject["baseRate"] as? Double ?? 0.0
                            
                            let formatter = NumberFormatter()
                            formatter.numberStyle = .currency
                            formatter.currencySymbol = "€"
                            formatter.minimumFractionDigits = 2
                            formatter.maximumFractionDigits = 2
                            let baseRateString = formatter.string(from: NSNumber(value: baseRate)) ?? "\(baseRate)"
                            
                            personInfo = [storeNumber, firstName, lastName, self.getDateText(date: dateOfHire), jobTitle, baseRateString]
                        }
                    } else {
                        print("Error: loggedAssociateDetails not found")
                        personInfo = nil
                    }
                } catch {
                    print("Error: Invalid regular expression")
                    personInfo = nil
                }
            } else {
                print("Error: Unable to convert data to string")
                personInfo = nil
            }
        }
        
        // Wait for the network request to finish before returning the person info
        while personInfo == nil {}
        
        return personInfo
    }
    
    private func minToTime(_ minutes: Int) -> String {
        var hours = minutes / 60
        let newMinutes = (minutes - (hours * 60))
        var hoursLeadingZero = ""
        var minutesLeadingZero = ""
        
        if hours < 10 {
            hoursLeadingZero = "0"
        }
        if newMinutes < 10 {
            minutesLeadingZero = "0"
        }
        
        if hours >= 24 {
            hours = hours - 24
        }
        
        return "\(hoursLeadingZero)\(hours):\(minutesLeadingZero)\(newMinutes)"
    }
    
    private func getArrayOfShift() -> [Shift] {
        if !getShiftsJSON() {
            print("Login details incorrect!")
            return [Shift(fromInt: 0)]
        }
        let json = gShiftsJSON
        let decoder = JSONDecoder()

        do {
            shifts = try decoder.decode([Shift].self, from: json.data(using: .utf8)!)
            // loop through days of week, if missing day of week assign empty shift to shift array
            for day in gStartWeek!..<gStartWeek!+7 {
                if !shifts.contains(where: { $0.startDate == day }) {
                    let newShift = Shift(startDate: day, startTime: 0, duration: 0)
                    shifts.append(newShift)
                }
            }
            return shifts
        } catch {
            print("Error parsing JSON: \(error)")
        }
        return shifts
    }
    
    public func getShiftMessages() -> [String] {
        // turn our shifts json into a array of shifts
        let shifts = getArrayOfShift()
        for shift in shifts {
            if shift.startDate == 0
                && shift.startTime == 0
                && shift.duration == 0 {
                return ["undefined"]
            }
        }
        
        let sortedShifts = shifts.sorted { $0.startDate < $1.startDate }
        var shiftMessages = [String]()
        
        for shift in sortedShifts {
            if !(shift.startTime == 0 && shift.duration == 0) {
                let endTime = shift.startTime + shift.duration
                shiftMessages.append("\(minToTime(shift.startTime)) - \(minToTime(endTime))")
            } else {
                shiftMessages.append("Not Scheduled")
            }
        }
        print("hello: \(shiftMessages)")
        return shiftMessages
    }
}

private extension String {
    var length: Int {
        return count
    }
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}


