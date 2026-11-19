import { createHotContext as __vite__createHotContext } from "/@vite/client";import.meta.hot = __vite__createHotContext("/src/App.jsx");import __vite__cjsImport0_react_jsxDevRuntime from "/node_modules/.vite/deps/react_jsx-dev-runtime.js?v=d3e96864"; const jsxDEV = __vite__cjsImport0_react_jsxDevRuntime["jsxDEV"];
import * as RefreshRuntime from "/@react-refresh";
const inWebWorker = typeof WorkerGlobalScope !== "undefined" && self instanceof WorkerGlobalScope;
let prevRefreshReg;
let prevRefreshSig;
if (import.meta.hot && !inWebWorker) {
  if (!window.$RefreshReg$) {
    throw new Error(
      "@vitejs/plugin-react can't detect preamble. Something is wrong."
    );
  }
  prevRefreshReg = window.$RefreshReg$;
  prevRefreshSig = window.$RefreshSig$;
  window.$RefreshReg$ = RefreshRuntime.getRefreshReg("/app/src/App.jsx");
  window.$RefreshSig$ = RefreshRuntime.createSignatureFunctionForTransform;
}
var _s = $RefreshSig$();
import __vite__cjsImport3_react from "/node_modules/.vite/deps/react.js?v=d3e96864"; const useState = __vite__cjsImport3_react["useState"];
export default function App() {
  _s();
  const [contador, setContador] = useState(0);
  return /* @__PURE__ */ jsxDEV("main", { className: "container", children: [
    /* @__PURE__ */ jsxDEV("h1", { children: "Unifeg — React dentro de um container" }, void 0, false, {
      fileName: "/app/src/App.jsx",
      lineNumber: 27,
      columnNumber: 7
    }, this),
    /* @__PURE__ */ jsxDEV("p", { children: [
      "Edite este arquivo (",
      /* @__PURE__ */ jsxDEV("code", { children: "src/App.jsx" }, void 0, false, {
        fileName: "/app/src/App.jsx",
        lineNumber: 29,
        columnNumber: 29
      }, this),
      ") com o container rodando e observe o hot reload acontecer sem rebuild da imagem."
    ] }, void 0, true, {
      fileName: "/app/src/App.jsx",
      lineNumber: 28,
      columnNumber: 7
    }, this),
    /* @__PURE__ */ jsxDEV("button", { onClick: () => setContador((c) => c + 1), children: [
      "Cliques: ",
      contador
    ] }, void 0, true, {
      fileName: "/app/src/App.jsx",
      lineNumber: 32,
      columnNumber: 7
    }, this)
  ] }, void 0, true, {
    fileName: "/app/src/App.jsx",
    lineNumber: 26,
    columnNumber: 5
  }, this);
}
_s(App, "TatSB6kTJqmlLYw1AID1qIX14hw=");
_c = App;
var _c;
$RefreshReg$(_c, "App");
if (import.meta.hot && !inWebWorker) {
  window.$RefreshReg$ = prevRefreshReg;
  window.$RefreshSig$ = prevRefreshSig;
}
if (import.meta.hot && !inWebWorker) {
  RefreshRuntime.__hmr_import(import.meta.url).then((currentExports) => {
    RefreshRuntime.registerExportsForReactRefresh("/app/src/App.jsx", currentExports);
    import.meta.hot.accept((nextExports) => {
      if (!nextExports) return;
      const invalidateMessage = RefreshRuntime.validateRefreshBoundaryAndEnqueueUpdate("/app/src/App.jsx", currentExports, nextExports);
      if (invalidateMessage) import.meta.hot.invalidate(invalidateMessage);
    });
  });
}

//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJtYXBwaW5ncyI6IkFBT007Ozs7Ozs7Ozs7Ozs7Ozs7O0FBUE4sU0FBU0EsZ0JBQWdCO0FBRXpCLHdCQUF3QkMsTUFBTTtBQUFBQyxLQUFBO0FBQzVCLFFBQU0sQ0FBQ0MsVUFBVUMsV0FBVyxJQUFJSixTQUFTLENBQUM7QUFFMUMsU0FDRSx1QkFBQyxVQUFLLFdBQVUsYUFDZDtBQUFBLDJCQUFDLFFBQUcscURBQUo7QUFBQTtBQUFBO0FBQUE7QUFBQSxXQUF5QztBQUFBLElBQ3pDLHVCQUFDLE9BQUU7QUFBQTtBQUFBLE1BQ21CLHVCQUFDLFVBQUssMkJBQU47QUFBQTtBQUFBO0FBQUE7QUFBQSxhQUFpQjtBQUFBLE1BQU87QUFBQSxTQUQ5QztBQUFBO0FBQUE7QUFBQTtBQUFBLFdBR0E7QUFBQSxJQUNBLHVCQUFDLFlBQU8sU0FBUyxNQUFNSSxZQUFZLENBQUNDLE1BQU1BLElBQUksQ0FBQyxHQUFHO0FBQUE7QUFBQSxNQUN0Q0Y7QUFBQUEsU0FEWjtBQUFBO0FBQUE7QUFBQTtBQUFBLFdBRUE7QUFBQSxPQVJGO0FBQUE7QUFBQTtBQUFBO0FBQUEsU0FTQTtBQUVKO0FBQUNELEdBZnVCRCxLQUFHO0FBQUEsS0FBSEE7QUFBRyxJQUFBSztBQUFBLGFBQUFBLElBQUEiLCJuYW1lcyI6WyJ1c2VTdGF0ZSIsIkFwcCIsIl9zIiwiY29udGFkb3IiLCJzZXRDb250YWRvciIsImMiLCJfYyJdLCJpZ25vcmVMaXN0IjpbXSwic291cmNlcyI6WyJBcHAuanN4Il0sInNvdXJjZXNDb250ZW50IjpbImltcG9ydCB7IHVzZVN0YXRlIH0gZnJvbSBcInJlYWN0XCI7XHJcblxyXG5leHBvcnQgZGVmYXVsdCBmdW5jdGlvbiBBcHAoKSB7XHJcbiAgY29uc3QgW2NvbnRhZG9yLCBzZXRDb250YWRvcl0gPSB1c2VTdGF0ZSgwKTtcclxuXHJcbiAgcmV0dXJuIChcclxuICAgIDxtYWluIGNsYXNzTmFtZT1cImNvbnRhaW5lclwiPlxyXG4gICAgICA8aDE+VW5pZmVnIOKAlCBSZWFjdCBkZW50cm8gZGUgdW0gY29udGFpbmVyPC9oMT5cclxuICAgICAgPHA+XHJcbiAgICAgICAgRWRpdGUgZXN0ZSBhcnF1aXZvICg8Y29kZT5zcmMvQXBwLmpzeDwvY29kZT4pIGNvbSBvIGNvbnRhaW5lciByb2RhbmRvXHJcbiAgICAgICAgZSBvYnNlcnZlIG8gaG90IHJlbG9hZCBhY29udGVjZXIgc2VtIHJlYnVpbGQgZGEgaW1hZ2VtLlxyXG4gICAgICA8L3A+XHJcbiAgICAgIDxidXR0b24gb25DbGljaz17KCkgPT4gc2V0Q29udGFkb3IoKGMpID0+IGMgKyAxKX0+XHJcbiAgICAgICAgQ2xpcXVlczoge2NvbnRhZG9yfVxyXG4gICAgICA8L2J1dHRvbj5cclxuICAgIDwvbWFpbj5cclxuICApO1xyXG59XHJcbiJdLCJmaWxlIjoiL2FwcC9zcmMvQXBwLmpzeCJ9