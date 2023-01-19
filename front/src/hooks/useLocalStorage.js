import { useState, useEffect } from "react";

const STORAGE_KEYS_PREFIX = "chessh-";

const useStorage = (storage, keyPrefix) => (storageKey, fallbackState) => {
  if (!storageKey)
    throw new Error(
      `"storageKey" must be a nonempty string, but "${storageKey}" was passed.`
    );

  const storedString = storage.getItem(keyPrefix + storageKey);
  let parsedObject = null;

  if (storedString !== null) parsedObject = JSON.parse(storedString);

  // eslint-disable-next-line react-hooks/rules-of-hooks
  const [value, setValue] = useState(parsedObject ?? fallbackState);

  // eslint-disable-next-line react-hooks/rules-of-hooks
  useEffect(() => {
    storage.setItem(keyPrefix + storageKey, JSON.stringify(value));
  }, [value, storageKey]);

  return [value, setValue];
};

// eslint-disable-next-line react-hooks/rules-of-hooks
export const useLocalStorage = useStorage(
  window.localStorage,
  STORAGE_KEYS_PREFIX
);
