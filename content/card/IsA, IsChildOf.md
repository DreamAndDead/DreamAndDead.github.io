---
created: 2024-05-19T08:44
draft: true
tags: 
- card
- ue
- reflection
---

# IsChildOf

IsChildOf 是 UStruct 的方法，可被 UClass 子类使用
用于检测类的父子关系

```cpp
FORCEINLINE UClass* operator*() const
{
	if (!Class || !Class->IsChildOf(T::StaticClass()))
	{
		return nullptr;
	}
	return Class;
}
```

查看内部的实现，有两种调用方式

```cpp
/** Returns true if this struct either is class T, or is a child of class T. This will not crash on null structs */
template<class T>
bool IsChildOf() const
{
	return IsChildOf(T::StaticClass());
}

COREUOBJECT_API bool IsChildOf( const UStruct* SomeBase ) const;
```

```cpp
Class->IsChildOf(T::StaticClass());
// or
Class->IsChildOf<T>();
```


# IsA

IsA 是 UObject 的方法，用于检测**某个UObject**的类型是否是**某个UClass**的子类

```cpp
FORCEINLINE T* GetDefaultObject() const
{
	UObject* Result = nullptr;
	if (Class)
	{
		Result = Class->GetDefaultObject();
		check(Result && Result->IsA(T::StaticClass()));
	}
	return (T*)Result;
}
```

