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

  const [value, setValue] = useState(parsedObject ?? fallbackState);

  useEffect(() => {
    storage.setItem(keyPrefix + storageKey, JSON.stringify(value));
  }, [value, storageKey]);

  return [value, setValue];
};

export const useLocalStorage = useStorage(
  window.localStorage,
  STORAGE_KEYS_PREFIX
);
