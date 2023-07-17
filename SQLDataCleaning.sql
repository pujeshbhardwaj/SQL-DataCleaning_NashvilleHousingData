select*
from PortfolioProject.dbo.NashvilleHousing



--Standardize Date Format (we need to remove time from date)

Select saleDate , convert(date, saledate) 
from PortfolioProject.dbo.NashvilleHousing

--So we will add a new column to our table and then udate it with converted date only
Alter table NashvilleHousing
Add SaleDateOnly date

Update NashvilleHousing
set SaleDateOnly = convert(date, saledate)

--Now if we want we can remove SaleDate column



--Lets see if there are null value in proprty address and figure out how we can fill that correctly

select*
from PortfolioProject.dbo.NashvilleHousing
where PropertyAddress is null

--For this we will do self join and see if samepar cell id have same address but also differnt unique id
--have also see a temp column where proprty adress null to fil with adress(by if null - ISNULL)
select a.[UniqueID ], a.PropertyAddress, a.ParcelID, b.ParcelID, b.PropertyAddress, b.[UniqueID ], ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing as a
join PortfolioProject.dbo.NashvilleHousing as b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

--Now lets fill null values with same address
update a
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress) 
from PortfolioProject.dbo.NashvilleHousing as a
join PortfolioProject.dbo.NashvilleHousing as b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null


-- Breaking Out address into individual columns (Address, City, State)
select PropertyAddress 
From PortfolioProject..NashvilleHousing

Select
substring(propertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
substring(propertyAddress, CHARINDEX(',', PropertyAddress) +1, len(propertyAddress)) as address
From PortfolioProject..NashvilleHousing
-- 1 used in substring after propertyaddress is to show position,   -1 is used to select things before the comma and +1 to select data after comma


--Now lets create two new columns and put this data into

Alter table NashvilleHousing
Add PropertySplitAddress Nvarchar(255)

Update NashvilleHousing
set PropertySplitAddress = substring(propertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) 

Alter table NashvilleHousing
Add PropertySplitCity Nvarchar(255)

Update NashvilleHousing
set PropertySplitCity = substring(propertyAddress, CHARINDEX(',', PropertyAddress) +1, len(propertyAddress))

select *
From PortfolioProject..NashvilleHousing

-- Added and updated two new column by spliting adress



--Now lets split more complex owner address (Adress, city and adress) in simpler way without using subqueries

select OwnerAddress
From PortfolioProject..NashvilleHousing

select
PARSENAME (replace(ownerAddress, ',','.'), 3),
PARSENAME (replace(ownerAddress, ',','.'), 2),
PARSENAME (replace(ownerAddress, ',','.'), 1)
From PortfolioProject..NashvilleHousing

--since parsename only runs with periods '.' su we have to replace ',' by '.'

-- So we can easily use this as subquery to create new column and update value in it.

Alter table NashvilleHousing
Add OwnerSplitAddress Nvarchar(255)

Update NashvilleHousing
set OwnerSplitAddress = PARSENAME (replace(ownerAddress, ',','.'), 3)

Alter table NashvilleHousing
Add OwnerSplitCity Nvarchar(255)

Update NashvilleHousing
set OwnerSplitCity = PARSENAME (replace(ownerAddress, ',','.'), 2)

Alter table NashvilleHousing
Add OwnerSplitState Nvarchar(255)

Update NashvilleHousing
set OwnerSplitState = PARSENAME (replace(ownerAddress, ',','.'), 1)

select *
From PortfolioProject..NashvilleHousing



-- Lets change Y and N to Yes and No in "Sold as Vacant" field

--For this lets check how many Y and N values are there (by using Distinct )
Select Distinct(SoldAsVacant), count(SoldAsVacant)
From PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 2


--Now for this we will be using replace statement
Select SoldAsVacant
, case when SoldAsVacant = 'Y' then 'Yes'
       when SoldAsVacant = 'N' then 'No'
	   Else SoldAsVacant 
	   End
From PortfolioProject..NashvilleHousing


Update NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
       when SoldAsVacant = 'N' then 'No'
	   Else SoldAsVacant 
	   End






-- Remove Duplicates

select*,
ROW_NUMBER() over (
Partition by ParcelID,
             PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 order by 
			 uniqueID) row_num

From PortfolioProject..NashvilleHousing
order by ParcelID
--Now lets check for row_num column after running above query to see if there are duplicate rows which will be with '2' in row_num column
--Now lets select rows which are duplicate ie which are row_num > 1 (for this we have to create CTE)

With RowNumCTE as (
select*,
ROW_NUMBER() over (
Partition by ParcelID,
             PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 order by 
			 uniqueID) row_num

From PortfolioProject..NashvilleHousing
--order by ParcelID
)
select*
from RowNumCTE
where row_num>1 
order by PropertyAddress

--so there are about 104 rows whith row_num = 2 which are duplicate so lets just dlt them.

With RowNumCTE as (
select*,
ROW_NUMBER() over (
Partition by ParcelID,
             PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 order by 
			 uniqueID) row_num

From PortfolioProject..NashvilleHousing
--order by ParcelID
)
delete
from RowNumCTE
where row_num>1 
--order by PropertyAddress

-- to check duplicte is deleted we can again run and check query above delete to see all duplicates are deleted.




--Delete unused columns

select *
From PortfolioProject..NashvilleHousing

Alter table PortfolioProject.dbo.NashvilleHousing
drop column OwnerAddress, TaxDistrict, PropertyAddress, SaleDate