function JsonParser(str) {
  let i = 0;

  const value = parseValue();
  expectEndOfInput();
  return value;

  function parseValue() {
    skipWhitespace();
    const value =
      parseString() ??
      parseNumber() ??
      parseArray() ??
      parseObject() ??
      parseKeyword('true', true) ??
      parseKeyword('false', false) ??
      parseKeyword('null', null);
    skipWhitespace();

    return value;
  }

  function parseObject() {
    if (str[i] === "{") {
      i++;
      skipWhitespace();
      const result = {};
      let init = true;
      while (i < str.length && str[i] !== "}") {
        if (!init) {
          eatComma();
          skipWhitespace();
        }
        const key = parseString();
        if (key === undefined) {
          expectObjectKey();
        }

        eatColon();
        skipWhitespace();
        const value = parseValue();
        result[key] = value;
        init = false;
      }
      expectNotEndOfInput("}");
      i++;
      return result;
    }
  }

  function parseArray() {
    if (str[i] === "[") {
      i++;
      skipWhitespace();
      const result = [];
      let init = true;
      while (i < str.length && str[i] != "]") {
        if (!init) {
          eatComma();
        }
        const value = parseValue();
        result.push(value);
        init = false;
      }
      expectNotEndOfInput("]");
      i++;
      return result;
    }
  }

  function parseString() {
    if (str[i] === '"') {
      i++;
      let result = "";
      while (i < str.length && str[i] !== '"') {
        if (str[i] === "\\") {
          const char = str[i + 1];
          if (
            char === '"' ||
            char === "\\" ||
            char === "/" ||
            char === "b" ||
            char === "f" ||
            char === "n" ||
            char === "r" ||
            char === "t"
          ) {
            result += char;
            i++;
          } else if (char === "u") {
            if (
              isHexadecimal(str[i + 2]) &&
              isHexadecimal(str[i + 3]) &&
              isHexadecimal(str[i + 4]) &&
              isHexadecimal(str[i + 5])
            ) {
              result += String.fromCharCode(
                parseInt(str.slice(i + 2, i + 6), 16)
              );
              i += 5;
            } else {
              i += 2;
              expectEscapeUnicode(result);
            }
          } else {
            expectEscapeCharacter(result);
            // TODO: could remove?
            // result += str[i];
          }
        } else {
          result += str[i];
        }
        i++;
      }
      expectNotEndOfInput('"');
      i++;
      return result;
    }
  }

  function isHexadecimal(char) {
    return (
      (char >= "0" && char <= "9") ||
      (char.toLowerCase() >= "a" && char.toLowerCase() <= "f")
    );
  }

  function parseNumber() {
    let start = i;
    if (str[i] === '-') {
      i++;
      expectDigit(str.slice(start, i));
    }
    if (str[i] === "0") {
      i++;
    } else if (str[i] >= "1" && str[i] <= "9") {
      i++;
      while (str[i] >= "0" && str[i] <= "9") {
        i++;
      }
    }

    if (str[i] === ".") {
      i++;
      expectDigit(str.slice(start, i));
      while (str[i] >= "0" && str[i] <= "9") {
        i++;
      }
    }

    if (str[i] === "e" || str[i] === "E") {
      i++;
      if (str[i] === "-" || str[i] === "+") {
        i++;
      }
      expectDigit(str.slice(start, i));

      while (str[i] >= "0" && str[i] <= "9") {
        i++;
      }
    }

    if (i > start) {
      return Number(str.slice(start, i));
    }
  }

  function parseKeyword(name, value) {
    if (str.slice(i, i + name.length) === name) {
      i += name.length;
      return value;
    }
  }

  function skipWhitespace() {
    while (
      str[i] === " " ||
      str[i] === "\n" ||
      str[i] === "\t" ||
      str[i] === "\r"
    ) {
      i++;
    }
  }

  function eatComma() {
    expectCharacter(",");
    i++;
  }

  function eatColon() {
    expectCharacter(":");
    i++;
  }

  // error handling
  function expectNotEndOfInput(expected) {
    if (i === str.length) {
      printCodeSnippet(`Expecting a \`${expected}\` here`);
      throw new Error("JSON_ERROR_0001 UNEXPECTED END OF INPUT");
    }
  }

  function expectEndOfInput() {
    if (i < str.length) {
      printCodeSnippet("Expecting to end here");
      throw new Error("JSON_ERROR_0002 EXPECTED END OF INPUT");
    }
  }

  function expectObjectKey() {
    printCodeSnippet(`Expecting object key here

For example:
{ "foo", "bar" }
  ^^^^^`);
    throw new Error("JSON_ERROR_0003 EXPECTING JSON KEY");
  }

  function expectCharacter(expected) {
    if (str[i] !== expected) {
      printCodeSnippet(`Expecting a \`${expected}\` here`);
      throw new Error("JSON_ERROR_0004 UNEXPECTED TOKEN");
    }
  }

  function expectDigit(cur_num) {
    if (!(str[i] >= "0" && str[i] <= "9")) {
      printCodeSnippet(`JSON_ERROR_0005 EXPECTING A DIGIT here

For example:
${cur_num}
${" ".repeat(cur_num.length)}^`);
      throw new Error("JSON_ERROR_0006 Expecting a digit");
    }
  }

  function expectEscapeCharacter(cur_str) {
    printCodeSnippet(`Json_error_0007 Expecting escape expectCharacter

For example:
"${cur_str}\\n"
${" ".repeat(cur_str.length + 1)}^^
List of escape characters are: \\", \\\\, \\/, \\b, \\f, \\n, \\r, \\t, \\u`);
    throw new Error("Json_error_0008 Expecting an escape character");
  }

  function expectEscapeUnicode(cur_str) {
    printCodeSnippet(`Expect escape unicode

For example:
"${cur_str}"\\u0123
${" ".repeat(cur_str.length + 1)}^^^^^^`);

    throw new Error("Json_error_0009 Expecting an escape unicode");
  }

  function printCodeSnippet(message) {
    const from = Math.max(0, i - 10);
    const trimmed = from > 0;
    const padding = (trimmed ? 4 : 0) + (i - from);
    const snippet = [
      (trimmed ? "... " : "") + str.slice(from, i + 1),
      " ".repeat(padding) + "^",
      " ".repeat(padding) + message
    ].join("\n");
    console.log(snippet);
  }
}

// Fail cases:
// printCase("-");
// printCase("-1.");
// printCase("-0");
// printCase("1e");
// printCase("-1e-2.2");
// printCase('{ "key": -1e-2.2}');
// printCase("{");
// printCase("{}{");
// printCase('{"a"');
// printCase('{"a": "b",');
// printCase('{"a":"b""c"');
// printCase('{"a":"foo\\}');
// printCase('{"a":"foo\\u"}');
// printCase("[");
// printCase("[][");
// printCase("[[]");
// printCase('["]');
// printCase('{ "data": { "fish": "cake", "array": [1,2,3], "children": [ { "something": "else" }, { "candy": "cane" }, { "sponge": "bob" } ] } } ');
// printCase('{ "data": "test" } ');
printCase('{"key": "\u0061" }');

function printCase(json) {
  try {
    console.log(`JsonParser('${json}')`);
    let result = JsonParser(json);
    console.log(result);
  } catch (error) {
    console.error(error);
  }
}
