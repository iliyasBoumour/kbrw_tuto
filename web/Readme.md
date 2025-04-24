# KBRW front-enf architecture

When a url changes an event `popstate` is trigerred and our app is listening to this event and it handles it by calling a callback function that gets `the browser state`and pass it as prop to all childs

## The browser state object

the `browserState` is a global object with the type:

```typescript
type BrowserState {
  path: string;
  qs: string;
  cookie: Record<string, string>;
  Child: React.ReactNode;
  route: string;
} & RouteProps

type RouteProps =  {
    handlerPath: React.ReactNode[] // the tree of the components to render
} & Record<string, any|undefined>
```

As we can see the `browserState` extends another global object called `routes` (it gets its props by calling its function match) and with type:

```typescript
// string is the routeKey
type Routes = Record<string, Route>;

interface Route {
  path: (params) => string;
  match: (path, qs) => false | RouteProps;
}
```

## Show the component

If the component needs some data from the api, we should add a static property to it, like:

```javascript
// for example a component orders need to retrieve orders from the api
statics: {
remoteProps: [remoteProps.orders],
}
```

As you can see all our remote props are stored in a global object called `remoteProps`

```typescript
type RemotePropFn = (props: BrowserState) => {
  url: string;
  prop: string;
  value?: any | undefined;
};

type RemoteProps = Record<string, RemotePropFn>;
// Note that the record key should be equal to the prop returned by the function `RemotePropFn`
```

## fetch data

In order to fetch data we have to call a function called `addRemoteProps` (this function is getting called automaticcaly each time the route changes) and pass a `BrowserState` data to it this function does the following:

- get all components tree's `remoteProps`
- call the `remoteProps`'s function with the browserState

- filter all unneeded api calls by checking if the `browserState` already has the data (by checking if BrowserState.[RemotePropFn().prop].url value is already resolved)
