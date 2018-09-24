import UIKit

enum LogLevel: Int
{
	case error, debug
}

func <(lhs: LogLevel, rhs: LogLevel) -> Bool
{
	return lhs.rawValue < rhs.rawValue
}

func <=(lhs: LogLevel, rhs: LogLevel) -> Bool
{
	return lhs.rawValue < rhs.rawValue
}

func >(lhs: LogLevel, rhs: LogLevel) -> Bool
{
	return lhs.rawValue > rhs.rawValue
}

func >=(lhs: LogLevel, rhs: LogLevel) -> Bool
{
	return lhs.rawValue >= rhs.rawValue
}


class Logger: NSObject
{
	var logLevel: LogLevel

	private let fileHandle: FileHandle!

	init(withFilename filename: String!, andLevel logLevel: LogLevel = .error)
	{
		self.fileHandle = Logger.open(filename: filename)
		self.logLevel = logLevel
	}

	deinit
	{
		self.fileHandle.closeFile()
	}

	func log(_ content: String, level: LogLevel)
	{
		if level >= self.logLevel
		{
			do
			{
				try self.fileHandle.append(content)
				try self.fileHandle.newLine()
			}
			catch
			{
				debugPrint("[Logger append] \(error)")
			}
		}
	}

	func logDebug(_ content: String)
	{
		self.log(content, level: .debug)
	}

	// MARK: - Private

	private static func open(filename: String!) -> FileHandle
	{
		assert(!filename.isEmpty, "[Logger open] filename should not be empty")

		let fileManager = FileManager.default
		guard let documentDirectory = fileManager.urls(for: .documentDirectory,
													   in: .userDomainMask).first else
		{
			fatalError("[Logger open] Cannot locate Document folder.")
		}
		let filepath = documentDirectory.appendingPathComponent(filename)
		try? fileManager.removeItem(at: filepath)
		fileManager.createFile(atPath: filepath.path, contents: nil, attributes: nil)
		do
		{
			let fileHandle = try FileHandle(forWritingTo: filepath)
			return fileHandle
		}
		catch
		{
			fatalError("[Logger open] \(error)")
		}
	}
}

enum FileHandleError: Error
{
	case encodingError
}

extension FileHandle
{
	func append(_ string: String) throws
	{
		self.seekToEndOfFile()
		if let data = string.data(using: .utf8)
		{
			self.write(data)
		}
		else
		{
			throw FileHandleError.encodingError
		}
	}

	func newLine() throws
	{
		try self.append("\n")
	}
}
