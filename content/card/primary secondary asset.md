---
created: 2024-05-17T17:02
draft: true
tags: 
- card
- ue
- asset
---

# 两种类型的区别

[资产分成两种类型](https://blog.uwa4d.com/archives/USparkle_Unrealassets.html)：Primary Asset和Secondary Assets

Primary Asset可以由AssetManager通过GetPrimaryAssetId获取PrimaryAssetId进行手动操作。

![[Pasted image 20240517110252.png]]


> [!NOTE] 默认只有  level 是 primary asset
> 只有 uworld 类 override GetPrimaryAssetId()


Secondary Assets通过与 primary asset 的引用关系，由引擎自动加载。

如 Mesh、Texture、Audio 等

# 转化为 primary asset

将 secondary asset 转化为 primary asset，就可以通过 asset manager 进行管理

## cpp 派生的 bp 类

覆盖GetPrimaryAssetId以返回一个有效的FPrimaryAssetId结构体

```cpp
virtual FPrimaryAssetId GetPrimaryAssetId() const override;

FPrimaryAssetId AMyActor::GetPrimaryAssetId() const
{
	UPackage* Package = GetOutermost();

	if (!Package->HasAnyPackageFlags(PKG_PlayInEditor))
	{
		return FPrimaryAssetId(UAssetManager::PrimaryAssetLabelType, Package->GetFName());
	}

	return FPrimaryAssetId();
}
```

## mesh, texture 等其它

通过 data asset

继承UPrimaryDataAsset，在类中添加资产引用，需要重写GetPrimaryAssetId()方法，指定自定义的PrimaryAssetType



