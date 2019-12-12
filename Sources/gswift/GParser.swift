//
//  GParser.swift
//  gswift
//
//  Created by Muhammet Mehmet Emin Kartal on 10/24/19.
//  Copyright © 2019 Cabbage Soft, Inc. All rights reserved.
//


import Foundation

extension Array {
	func joined(with seperator: String, map: (Element) -> String ) -> String {
		var buffer = ""

		for i in self.enumerated() {
			buffer += map(i.element)
			if i.offset < self.count - 1 {
				buffer += seperator
			}
		}
		return buffer
	}
}

public class GParser {
	var fileHandler: UnsafeMutablePointer<FILE>? = nil
	public init(path: String) {
		//		if let filePath = Bundle(for: ObjectPreviewView.self).path(forResource: "sample", ofType: "gcode") {
		fileHandler = fopen(path, "r")
		//		} else {
		//			fatalError()
		//		}
	}


	public func getNextChar() -> Character? {

		let ch = fgetc(fileHandler)

		if ch < 0 {
			return nil
		}

		return Character(UnicodeScalar(UInt8(ch)))
	}



	func startReading() {


		let tokens = tokenize()


		//		print(tokens)

		for i in tokens {

			print(i.toString)
		}

		print("End!")

	}


	public enum GToken: Equatable & Hashable {
		case g(num: Int?, parameters: [GParams])
		case m(num: Int?, parameters: [GParams])
		case comment(_ str: String)

		func appending(param: GParams) -> GToken {
			switch self {
			case .g(let num, let parameters):
				return .g(num: num, parameters: parameters + [param])
			case .m(let num, let parameters):
				return .m(num: num, parameters: parameters + [param])
			case .comment(_):
				return self
			}
		}

		var toString: String {
			switch self {

			case .g(let num, let parameters):
				return "G\(num!) \(parameters.joined(with: " ", map: { $0.toString }))"
			case .m(let num, let parameters):
				return "M\(num!) \(parameters.joined(with: " ", map: { $0.toString }))"
			case .comment(let val):
				return "; \(val)"
			}
		}
	}

	public enum GParams: Equatable & Hashable {

		case xAxis(value: Double?)
		case yAxis(value: Double?)
		case zAxis(value: Double?)
		case eAxis(value: Double?)

		case scalar(value: Double?)
		case speed(value: Double?)
		case time(value: Double?)
		case print(value: Double?)
		case radius(value: Double?)

		case string(value: String)

		var toString: String {
			switch self {

			case .xAxis(let value):
				return "X\(value == nil ? "" : String(value!))"
			case .yAxis(let value):
				return "Y\(value == nil ? "" : String(value!))"
			case .zAxis(let value):
				return "Z\(value == nil ? "" : String(value!))"
			case .eAxis(let value):
				return "E\(value == nil ? "" : String(value!))"
			case .scalar(let value):
				return "S\(value == nil ? "" : String(value!))"
			case .speed(let value):
				return "F\(value == nil ? "" : String(value!))"
			case .time(let value):
				return "T\(value == nil ? "" : String(value!))"
			case .print(let value):
				return "P\(value == nil ? "" : String(value!))"
			case .radius(let value):
				return "R\(value == nil ? "" : String(value!))"
			case .string(let value):
				return "\(value); String"
			}
		}

		func applying(value: Double) -> GParams {
			switch self {
			case .xAxis(_):
				return .xAxis(value: value)
			case .yAxis(_):
				return .yAxis(value: value)
			case .zAxis(_):
				return .zAxis(value: value)
			case .eAxis(_):
				return .eAxis(value: value)
			case .scalar(_):
				return .scalar(value: value)
			case .time(_):
				return .time(value: value)
			case .speed(_):
				return .speed(value: value)

			case .print(_):
				return .print(value: value)
			case .radius(_):
				return .radius(value: value)
			default:
				return self
			}
		}
	}



	func endToken() {
		if let donecode = code {
			tokens.append(donecode)
			code = nil
		}
	}

	var numberBuffer: String = ""

	var tokens: [GToken] = []


	var params: [GParams] = []

	var code: GToken? = nil
	var param: GParams? = nil



	public func tokenize() -> [GToken]{

		while let a = getNextChar() {
			//			print("Char = \(a)")


			switch a {
			case "M":

				endToken()

				code = .m(num: nil, parameters: [])
				//				print("M Code Start")


			case "G":
				endToken()
				code = .g(num: nil, parameters: [])
				//				print("G Code Start")

			case "X", "Y", "Z", "E", "P", "R":
				//				print("Axis \(a)")
				switch a {
				case "X": param = .xAxis(value: nil)
				case "Y": param = .yAxis(value: nil)
				case "Z": param = .zAxis(value: nil)
				case "E": param = .eAxis(value: nil)
				case "P": param = .print(value: nil)
				case "R": param = .radius(value: nil)

				default:
					break
				}
			case "F":
				//				print("Speed \(a)")
				param = .speed(value: nil)

			case "S":
				param = .scalar(value: nil)
			case "T":
				param = .time(value: nil)
			//				print("Scalar Value \(a)")
			case " ", "\n": // End of current segment
				if numberBuffer != "" {
					if let currentParam = param {
						switch currentParam {
						case .xAxis(nil), .yAxis(nil), .zAxis(nil), .eAxis(nil), .scalar(nil), .time(nil), .speed(nil), .print(nil), .radius(nil):
							if let number = Double(numberBuffer) {
								code = code?.appending(param: currentParam.applying(value: number))
								//								print("Parsed \(currentParam) number: \(number)")
								numberBuffer = ""
								param = nil
								break
							} else {
								code = code?.appending(param: currentParam)
								numberBuffer = ""
								param = nil
							}
						default:
							break
						}
					} else if let currentCode = code {
						switch currentCode {
						case .g(num: let val, parameters: _):
							if val == nil {
								if let number = Int(numberBuffer) {
									// Corrent number
									code = .g(num: number, parameters: [])
									//									print("Parsed G number: \(number)")
									numberBuffer = ""
									break
								}
							}
						case .m(num: let val, parameters: _):
							if val == nil {
								if let number = Int(numberBuffer) {
									// Corrent number
									code = .m(num: number, parameters: [])
									//									print("Parsed G number: \(number)")
									numberBuffer = ""
									break
								}
							}

							break
						case .comment(_):
							break
						}
					}



					if Double(numberBuffer) != nil {
						// Corrent number
						fatalError("Non matching number")
						//						print("Parsed number: \(number)")
					} else {
						//						print("LOL \(numberBuffer)")
						//
					}

					numberBuffer = ""
				} else {
					if let currentParam = param {
						code = code?.appending(param: currentParam)
						numberBuffer = ""
						param = nil
					} else if code != nil {
						endToken()
					}

				}
				break
			case "&":
				endToken()
				return tokens
			case ";":
				var comment = ""
				while let c = getNextChar(), c != "\n" { comment.append(c) }

				//				print("Comment: \(comment)")
				break
			case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "-":
				numberBuffer.append(a)
				break
			default:
				break
				//				print("Invalid \(a)")
			}
		}
		endToken()
		return tokens
	}

}
