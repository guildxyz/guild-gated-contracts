module.exports = {
  eq(one, other) {
    if (one === other) {
      return `${one}`;
    }
    return "";
  },
  or(one, other) {
    if (one || other) {
      return true;
    }
    return false;
  },
  printParams(params) {
    const mappedParams = params.map((param) => {
      if (param.name) {
        return `${param.type} ${param.name}`;
      }
      return param.type;
    });
    return mappedParams.join(", ");
  }
};
