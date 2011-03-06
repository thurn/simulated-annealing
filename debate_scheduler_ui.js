// Google Apps Script for a Spreadsheet front-end to the simulated annealing
// debate scheduler.

// The address of the server. POST to /debate_schedule here with a JSON
// representation of the tournament state to get a schedule for the
// next round of the tournament
var SERVER = "http://97.107.131.199:4567/";

// Populates the spreadsheet with the Tournament menu, which enables the
// user to calculate current tournament standings and to schedule the
// next round of the tournament
function onOpen() {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var menuEntries = [
        {name: "Generate Next Round", functionName: "generate"},
        {name: "Calculate Standings", functionName: "calculateStandings"}
    ];
    ss.addMenu("Tournament", menuEntries);
}

// Contacts the SERVER with the teams and judges in the tournament to get a
// tournament schedule for the next round. The next round number is pulled
// out of cell L2. When the server comes back with a schedule for the next
// round, creates a new sheet to display the matches in that round.
function generate() {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var regSheet = ss.getSheetByName("Registration");
    var teams = getRowsData(regSheet, regSheet.getRange("A2:D999"));
    initializeNumWins(teams);
    populateWinLoss(teams, ss);
    var judges = getRowsData(regSheet, regSheet.getRange("F2:G999"));
    var penalties = getRowsData(regSheet, regSheet.getRange("I2:J999"));
    var roundNumRange = regSheet.getRange("L2");
    var roundNum = parseInt(roundNumRange.getValue(), 10);

    if (isNaN(roundNum) || roundNum <= 0) {
        throw "Please enter a valid round number for the next round";
    }

    var json = Utilities.jsonStringify({"teams": teams, "judges": judges, "penalties": penalties});
    var response = UrlFetchApp.fetch(SERVER + "debate_schedule", {method: 'post', payload: json});

    if (response.getResponseCode() !== 200) {
        throw "Error contacting server: " + SERVER;
    }

    var schedule = Utilities.jsonParse(response.getContentText());
    var newSheet = ss.insertSheet("Round " + roundNum);
    newSheet.setColumnWidth(3, 200);
    var columns = ["Team A", "Team B", "Judges", "Winner"];
    newSheet.getRange("A1:D1").setValues([columns]).setFontWeight("bold");
    setRowsData(newSheet, schedule);
    roundNumRange.setValue(roundNum + 1);
}

// Calculates the number of wins for each team registered and displays the
// results in the "Standings" sheet, sorted by number of wins
function calculateStandings() {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var regSheet = ss.getSheetByName("Registration");
    var teams = getRowsData(regSheet, regSheet.getRange("A2:D999"));
    initializeNumWins(teams);
    populateWinLoss(teams, ss);
    var standingsSheet = ss.getSheetByName("Standings");
    var results = [];
    for (var i = 0; i < teams.length; ++i) {
        results.push({"teamName": teams[i]["teamName"], "numWins": String(teams[i]["numWins"])});
    }
    setRowsData(standingsSheet, results);
    standingsSheet.sort(2, false);
    ss.setActiveSheet(standingsSheet);
}

// Updates the specified teams array by setting the numWins attribute for each team to 0.
// Arguments
//   - An array of team objects
function initializeNumWins(teams) {
    for (var i = 0; i < teams.length; ++i) {
        teams[i]["numWins"] = 0;
    }
}

// Updates the specified teams array by giving each team object the numWins
// attribute, holding the number of wins for that team recorded in the spreadsheet
// Arguments
//   - teams: An array of team objects
//   - ss: The Spreadsheet object to act on
function populateWinLoss(teams, ss) {
    var currRoundNum = 1;
    while (true) {
        var currSheet = ss.getSheetByName("Round " + currRoundNum);
        if (currSheet === null) {
            break;
        }
        var data = getRowsData(currSheet, currSheet.getRange("A2:D999"));
        for (var i = 0; i < data.length; ++i) {
            var winner = data[i]["winner"];
            if (typeof(winner) === "undefined") {
                throw "Please enter the winner of each match in the current round.";
            }
            var team = findTeamByName(winner, teams);
            if ((data[i]["teamA"] === winner || data[i]["teamB"] === winner) &&
                    team !== null) {
                team["numWins"] = team["numWins"] + 1;
            }
            else {
                throw "Unknown Winner: " + winner + " must be one of " +
                        data[i]["teamA"] + " or " + data[i]["teamB"];
            }
        }
        currRoundNum += 1;
    }
}

// Given a team name and an array of team objects, locate the team with this name
// Arguments:
//   - teamName: The name of the team, as a string
//   - teams: An array of team objects
// Returns the team object with the given name
function findTeamByName(teamName, teams) {
    for (var i = 0; i < teams.length; ++i) {
        if (teams[i]["teamName"] === teamName) {
            return teams[i]
        }
    }
    return null;
}







// -------------------------------------------------------------------------------
// Standard spreadsheet manipulation functions from the Apps Script documentation:
// -------------------------------------------------------------------------------







// getRowsData iterates row by row in the input range and returns an array of objects.
// Each object contains all the data for a given row, indexed by its normalized column name.
// Arguments:
//   - sheet: the sheet object that contains the data to be processed
//   - range: the exact range of cells where the data is stored
//   - columnHeadersRowIndex: specifies the row number where the column names are stored.
//       This argument is optional and it defaults to the row immediately above range;
// Returns an Array of objects.
function getRowsData(sheet, range, columnHeadersRowIndex) {
    columnHeadersRowIndex = columnHeadersRowIndex || range.getRowIndex() - 1;
    var numColumns = range.getEndColumn() - range.getColumn() + 1;
    var headersRange = sheet.getRange(columnHeadersRowIndex, range.getColumn(), 1, numColumns);
    var headers = headersRange.getValues()[0];
    return getObjects(range.getValues(), normalizeHeaders(headers));
}

// setRowsData fills in one row of data per object defined in the objects Array.
// For every Column, it checks if data objects define a value for it.
// Arguments:
//   - sheet: the Sheet Object where the data will be written
//   - objects: an Array of Objects, each of which contains data for a row
//   - optHeadersRange: a Range of cells where the column headers are defined. This
//     defaults to the entire first row in sheet.
//   - optFirstDataRowIndex: index of the first row where data should be written. This
//     defaults to the row immediately below the headers.
function setRowsData(sheet, objects, optHeadersRange, optFirstDataRowIndex) {
    var headersRange = optHeadersRange || sheet.getRange(1, 1, 1, sheet.getMaxColumns());
    var firstDataRowIndex = optFirstDataRowIndex || headersRange.getRowIndex() + 1;
    var headers = normalizeHeaders(headersRange.getValues()[0]);

    var data = [];
    for (var i = 0; i < objects.length; ++i) {
        var values = []
        for (j = 0; j < headers.length; ++j) {
            var header = headers[j];
            values.push(header.length > 0 && objects[i][header] ? objects[i][header] : "");
        }
        data.push(values);
    }

    var destinationRange = sheet.getRange(firstDataRowIndex, headersRange.getColumnIndex(),
            objects.length, headers.length);
    destinationRange.setValues(data);
}

// For every row of data in data, generates an object that contains the data. Names of
// object fields are defined in keys.
// Arguments:
//   - data: JavaScript 2d array
//   - keys: Array of Strings that define the property names for the objects to create
function getObjects(data, keys) {
    var objects = [];
    for (var i = 0; i < data.length; ++i) {
        var object = {};
        var hasData = false;
        for (var j = 0; j < data[i].length; ++j) {
            var cellData = data[i][j];
            if (isCellEmpty(cellData)) {
                continue;
            }
            object[keys[j]] = cellData;
            hasData = true;
        }
        if (hasData) {
            objects.push(object);
        }
    }
    return objects;
}

// Returns an Array of normalized Strings.
// Arguments:
//   - headers: Array of Strings to normalize
function normalizeHeaders(headers) {
    var keys = [];
    for (var i = 0; i < headers.length; ++i) {
        var key = normalizeHeader(headers[i]);
        if (key.length > 0) {
            keys.push(key);
        }
    }
    return keys;
}

// Normalizes a string, by removing all alphanumeric characters and using mixed case
// to separate words. The output will always start with a lower case letter.
// This function is designed to produce JavaScript object property names.
// Arguments:
//   - header: string to normalize
// Examples:
//   "First Name" -> "firstName"
//   "Market Cap (millions) -> "marketCapMillions
//   "1 number at the beginning is ignored" -> "numberAtTheBeginningIsIgnored"
function normalizeHeader(header) {
    var key = "";
    var upperCase = false;
    for (var i = 0; i < header.length; ++i) {
        var letter = header[i];
        if (letter == " " && key.length > 0) {
            upperCase = true;
            continue;
        }
        if (!isAlnum(letter)) {
            continue;
        }
        if (key.length == 0 && isDigit(letter)) {
            continue; // first character must be a letter
        }
        if (upperCase) {
            upperCase = false;
            key += letter.toUpperCase();
        } else {
            key += letter.toLowerCase();
        }
    }
    return key;
}

// Returns true if the cell where cellData was read from is empty.
// Arguments:
//   - cellData: string
function isCellEmpty(cellData) {
    return typeof(cellData) == "string" && cellData == "";
}

// Returns true if the character char is alphabetical, false otherwise.
function isAlnum(char) {
    return char >= 'A' && char <= 'Z' ||
            char >= 'a' && char <= 'z' ||
            isDigit(char);
}

// Returns true if the character char is a digit, false otherwise.
function isDigit(char) {
    return char >= '0' && char <= '9';
}

// Given a JavaScript 2d Array, this function returns the transposed table.
// Arguments:
//   - data: JavaScript 2d Array
// Returns a JavaScript 2d Array
// Example: arrayTranspose([[1,2,3],[4,5,6]]) returns [[1,4],[2,5],[3,6]].
function arrayTranspose(data) {
    if (data.length == 0 || data[0].length == 0) {
        return null;
    }

    var ret = [];
    for (var i = 0; i < data[0].length; ++i) {
        ret.push([]);
    }

    for (var i = 0; i < data.length; ++i) {
        for (var j = 0; j < data[i].length; ++j) {
            ret[j][i] = data[i][j];
        }
    }

    return ret;
}

// getColumnsData iterates column by column in the input range and returns an array of objects.
// Each object contains all the data for a given column, indexed by its normalized row name.
// Arguments:
//   - sheet: the sheet object that contains the data to be processed
//   - range: the exact range of cells where the data is stored
//   - rowHeadersColumnIndex: specifies the column number where the row names are stored.
//       This argument is optional and it defaults to the column immediately left of the range;
// Returns an Array of objects.
function getColumnsData(sheet, range, rowHeadersColumnIndex) {
    rowHeadersColumnIndex = rowHeadersColumnIndex || range.getColumnIndex() - 1;
    var headersTmp = sheet.getRange(range.getRow(), rowHeadersColumnIndex, range.getNumRows(), 1).getValues();
    var headers = normalizeHeaders(arrayTranspose(headersTmp)[0]);
}
