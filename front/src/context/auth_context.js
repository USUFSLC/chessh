import React, { useContext, useState, createContext } from "react";

export const DEFAULT_EXPIRY_TIME_MS = 12 * 60 * 60 * 1000;

const AuthContext = createContext({
  signedIn: false,
  setSignedIn: () => null,
  sessionOver: new Date(),
  setSessionOver: () => null,
  userId: null,
  setUserId: () => null,
  username: "",
  setUsername: () => null,
});

export const useAuthContext = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [signedIn, setSignedIn] = useState(false);
  const [sessionOver, setSessionOver] = useState(new Date());
  const [userId, setUserId] = useState(null);
  const [username, setUsername] = useState(null);

  return (
    <AuthContext.Provider
      value={{
        signedIn,
        setSignedIn,
        sessionOver,
        setSessionOver,
        userId,
        setUserId,
        username,
        setUsername,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
