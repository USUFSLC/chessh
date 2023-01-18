import React, { useContext, useState, createContext, useEffect } from "react";

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

  useEffect(() => {
    if (!signedIn) {
      setUsername(null);
      setUserId(null);
    }
  }, [signedIn]);

  useEffect(() => {
    if (userId) {
      localStorage.setItem("userId", userId.toString());
    }
  }, [userId]);

  useEffect(() => {
    if (username) {
      localStorage.setItem("username", username);
    }
  }, [username]);

  useEffect(() => {
    let expiry = localStorage.getItem("expiry");
    if (expiry) {
      expiry = new Date(expiry);
      if (Date.now() < expiry.getTime()) {
        setSignedIn(true);
        setSessionOver(expiry);
        // We don't have access to the JWT token as it is an HTTP only cookie -
        // so we store user info in local storage
        ((username) => {
          if (username) {
            setUsername(username);
          }
        })(localStorage.getItem("username"));

        ((id) => {
          if (id) {
            setUserId(parseInt(id, 10));
          }
        })(localStorage.getItem("userId"));
      }
    }
  }, []);

  useEffect(() => {
    localStorage.setItem("expiry", sessionOver.toISOString());
    setTimeout(() => {
      setSessionOver((sessionOver) => {
        if (Date.now() >= sessionOver.getTime()) {
          setSignedIn((signedIn) => {
            if (signedIn) {
              alert(
                "Session expired. Any further privileged requests will fail until signed in again."
              );
              ["userId", "userName"].map((x) => localStorage.removeItem(x));
              return false;
            }
            return signedIn;
          });
        }
        return sessionOver;
      });
    }, sessionOver.getTime() - Date.now());
  }, [sessionOver]);

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
