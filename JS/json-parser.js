JsonParser(content);

function JsonParser(str) {
  let i = 0;

  return parseValue();

  function parseObject() {
    if (str[i] == '{') {
      i++;
      const result = {};
      let init = true;
      skipWhitespace();
      while (str[i] !== '}') {
        if (!init) {
          eatComma();
          skipWhitespace();
        }
        const key = parseString();
        skipWhitespace();
        eatColon();
        const value = parseValue();
        result[key] = value;
        init = false;
      }
      i++;
      return result;
    }
  }

  function parseArray() {
    if (str[i] == '[') {
      i++;
      skipWhitespace();
      const result = [];
      let init = true;
      while (str[i] != ']') {
        if (!init) {
          eatComma();
        }
        const value = parseValue();
        result.push[value];
        init = false;
      }
      i++;
      return result;
    }
  }

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

  function parseString() {
    if (str[i] === '"') {
      i++;
      let result = "";
      while (str[i] !== '"') {
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
            }
          } else {
            result += str[i];
          }
          i++;
        }
      }
      i++;
      return result;
    }
  }

  function parseNumber() {
    // TODO:
    let start = i;

  }

  function isHexadecimal(char) {
    return (
      (char >= "0" && char <= "9") ||
      (char.toLowerCase() >= "a" && char.toLowerCase() <= "f")
    );
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
    if (str[i] != ",") {
      throw new Error("Expected ','.");
    }
    i++;
  }

  function eatColon() {
    if (str[i] != ":") {
      throw new Error("Expected ':'.");
    }
    i++;
  }
}

