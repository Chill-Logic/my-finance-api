// eslint-disable
export function After(methodName: string[] | string) {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;

    descriptor.value = async function (...params: any[]) {
      // eslint-disable-next-line
      const result = await originalMethod.apply(this, params);
      const props = {
        params,
        result
      };
      if (Array.isArray(methodName)) {
        for (const method of methodName) {
          // eslint-disable-next-line
          if (typeof this[method] === 'function') {
            // eslint-disable-next-line
            await this[method](props);
          }
        }
      } else if (typeof methodName === 'string' && methodName) {
        // eslint-disable-next-line
        if (typeof this[methodName] === 'function') {
        // eslint-disable-next-line
          await this[methodName](props);
        }
      }
      // eslint-disable-next-line
      return result;
    };
  };
}