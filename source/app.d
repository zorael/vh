/++
	This was "verbose head" once, now it's just `vh`.
 +/
module zor.vh;

private:

import argparse;

// Configuration
/++
	Configuration struct, for use with [argparse].
 +/
@(Command("vh2")
	.Description("I don't know, it used to be verbose head, now it's just vh.")
	.Epilog("Should work.")
)
struct Configuration
{
	@(NamedArgument([ "lines", "n" ])
		.Description("Number of lines to display.")
		.Placeholder("NUMBER"))
	uint numLines = 10;

	@(NamedArgument([ "colours", "colors", "c" ])
		.Description("Whether or not to use coloured output.")
		.Placeholder("BOOL"))
	bool colours = true;
}

/// Default buffer size for [ByLineFast].
enum byLineFastBufferSize = 8192L;

public:

// FileHead
/++
	Embodies the notion of the head of a file.
 +/
struct FileHead
{
private:
	import std.array : Appender;
	import std.file : DirEntry;

public:
	DirEntry dirEntry;
	string filename;
	Appender!(string[]) head;
	size_t lineCount;
}

// getNewBashColour
/++
	Returns a new ANSI colour token, cycling through the first 15.
 +/
string getNewBashColour()
{
	import zor.bashcolours : TerminalForeground, TerminalFormat;
	import std.conv : text;

	alias F = TerminalForeground;

    static immutable colours =
    [
        F.red,
        F.green,
        F.yellow,
        F.blue,
        F.magenta,
        F.cyan,
        F.lightgrey,
        F.darkgrey,
        F.lightred,
        F.lightgreen,
        F.lightyellow,
        F.lightblue,
        F.lightmagenta,
        F.lightcyan,
        F.white,
    ];

	static size_t currentIndex;
	if (currentIndex == colours.length) currentIndex = 0L;
	return text("\033[1;", cast(int)colours[currentIndex++], 'm');
}

// plurality
/++
 +  Given a number of items, return the singular word if it is a singular item
 +  (or negative one), else the plural word.
 +/
string plurality(ptrdiff_t num, string singular, string plural)
    pure nothrow @nogc @safe
{
    return ((num == 1) || (num == -1)) ? singular : plural;
}

// main
/++
	Entry point of the program.
 +/
mixin Main.parseCLIKnownArgs!(Configuration, (config, string[] trailing)
{
	import std.algorithm.comparison : min;
	import std.array : Appender;
	import std.stdio: stdout, write, writefln, writeln;

	size_t longestFilenameLength;
	size_t largestFileSize;
	uint numSkippedFiles;
	uint numSkippedDirs;
	uint numMissingFiles;

	void markSkipped(const char c = '!')
	{
		++numSkippedFiles;
		write(c);
		stdout.flush();
	}

	Appender!(FileHead[]) fileHeads;
	fileHeads.reserve(64);  // guesstimate
	if (trailing.length == 0) trailing = [ "." ];

	foreach (immutable path; trailing)
	{
		try
		{
			import std.file : DirEntry;

			void appendPath(DirEntry dirEntry)
			{
				import bylinefast;
				import std.algorithm.comparison : max;
				import std.array : Appender;
				import std.exception : ErrnoException;
				import std.range.primitives : walkLength;
				import std.stdio : File;

				if (dirEntry.isDir)
				{
					++numSkippedDirs;
					return;
				}

				FileHead fileHead;
				fileHead.dirEntry = dirEntry;
				File file;

				try
				{
					file = File(dirEntry.name, "r");
				}
				catch (ErrnoException e)
				{
					markSkipped('E');
					return;
				}

				auto byLines = ByLineFast(file, byLineFastBufferSize);
				cast(void)byLines.front;  // Quirk: evaluate front before iterating
				fileHead.head.reserve(config.numLines);

				while ((fileHead.head.data.length < config.numLines) && !byLines.empty)
				{
					import std.encoding : isValid;

					if (!isValid(byLines.front))
					{
						markSkipped();
						return;
					}

					fileHead.head.put(byLines.front.idup);
					byLines.popFront();
				}

				fileHead.lineCount = fileHead.head.data.length + byLines.walkLength();

				version(Posix)
				{
					enum currDirMarker = "./";
				}
				else version(Windows)
				{
					enum currDirMarker = ".\\";
				}

				fileHead.filename = (dirEntry.name[0..2] == currDirMarker) ?
					dirEntry.name[2..$] : dirEntry.name;
				longestFilenameLength = max(longestFilenameLength, fileHead.filename.length);
				largestFileSize = max(largestFileSize, fileHead.lineCount);

				fileHeads.put(fileHead);
				write('.');
				stdout.flush();
			}

			import std.file : exists, isDir;

			if (!path.exists)
			{
				++numMissingFiles;
				write('?');
				stdout.flush();
			}
			else if (path.isDir)
			{
				import std.algorithm.sorting : sort;
				import std.array : array;
				import std.file : SpanMode, dirEntries;

				auto range = dirEntries(path, SpanMode.shallow)
					.array
					.sort;

				foreach (entry; range)
				{
					appendPath(entry);
				}
			}
			else
			{
				appendPath(DirEntry(path));
			}
		}
		catch (Exception e)
		{
			writeln();
			writeln(e);
		}
	}

	if ((fileHeads.data.length > 0) ||
		(numMissingFiles > 0) ||
		(numSkippedFiles > 0))
	{
		writeln('\n');
	}

	static dumbLog10(const size_t number)
	{
		return
			(number < 10) ? 1 :
			(number < 100) ? 2 :
			(number < 1000) ? 3 :
			(number < 10_000) ? 4 :
			(number < 100_000) ? 5 :
			(number < 1_000_000) ? 6 :
			(number < 10_000_000) ? 7 :
			8;
	}

	immutable log10OfLineCount = dumbLog10(min(largestFileSize, config.numLines));

	foreach (immutable i, fileHead; fileHeads)
	{
		if (config.colours) write(getNewBashColour());

		if (config.numLines > 0)
		{
			foreach (immutable lineNumber, line; fileHead.head.data)
			{
				immutable maybeFilename = (lineNumber == 0) ? fileHead.filename : string.init;
				writefln!" %-*s  %*d: %s"(longestFilenameLength, maybeFilename, log10OfLineCount, lineNumber+1, line);
			}

			if (fileHead.lineCount > config.numLines)
			{
				if (config.colours) write("\033[0;0m");

				immutable linesTruncated = (fileHead.lineCount - fileHead.head.data.length);

				writefln!"   %-*s[%d %s truncated]"
					(longestFilenameLength, string.init, linesTruncated,
					linesTruncated.plurality("line", "lines"));
			}
		}
		else
		{
			writefln!" %-*s\033[0;0m  [%d %s truncated]"
				(longestFilenameLength, fileHead.filename, fileHead.lineCount,
				fileHead.lineCount.plurality("line", "lines"));
		}
	}

	if (fileHeads.data.length > 0) write('\n');
	if (config.colours) write("\033[0;0m");

	writefln!" %d %s listed, with %d %s and %d %s skipped."
		(fileHeads.data.length,
		fileHeads.data.length.plurality("file", "files"),
		numSkippedFiles,
		numSkippedFiles.plurality("file", "files"),
		numSkippedDirs,
		numSkippedDirs.plurality("directory", "directories"));

	return 0;
});
