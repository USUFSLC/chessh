import { useEffect, useContext, createContext } from "react";
import { useLocalStorage } from "../hooks/useLocalStorage";

const AuthContext = createContext({
  signedIn: false,
  setSignedIn: () => null,
  sessionOver: new Date(),
  setSessionOver: () => null,
  setPlayer: () => null,
  player: null,
  signOut: () => null,
});

export const useAuthContext = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [signedIn, setSignedIn] = useLocalStorage("signedIn", false);
  const [sessionOver, setSessionOver] = useLocalStorage(
    "sessionOver",
    Date.now()
  );
  const [player, setPlayer] = useLocalStorage("player", null);

  const setDefaults = () => {
    setPlayer(null);
    setSessionOver(Date.now());
    setSignedIn(false);
  };

  const signOut = () =>
    fetch("/api/player/logout", {
      method: "GET",
      credentials: "same-origin",
    }).then(() => setDefaults());

  useEffect(() => {
    setTimeout(() => {
      setSessionOver((sessionOver) => {
        if (Date.now() >= sessionOver) {
          setSignedIn((signedIn) => {
            if (signedIn)
              alert(
                "Session expired. Any further privileged requests will fail until signed in again."
              );

            return false;
          });
          setPlayer(null);
        }
        return sessionOver;
      });
    }, sessionOver - Date.now());
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sessionOver]);

  return (
    <AuthContext.Provider
      value={{
        signedIn,
        setSignedIn,
        sessionOver,
        setSessionOver,
        signOut,
        setPlayer,
        player,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
