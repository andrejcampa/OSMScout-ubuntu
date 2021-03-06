#include "DownloadListModel.h"

DownloadListItem::DownloadListItem( const QString& name,
             const QString& size,
             QObject* parent): QObject(parent)
{
    m_name = name;
    m_size = size;
}

DownloadListItem::~DownloadListItem()
{

}


QString DownloadListItem::getName() const
{
    return m_name;
}

QString DownloadListItem::getSize() const
{
    return m_size;
}


////////////////////////
DownloadListModel::DownloadListModel(QObject* parent): QAbstractListModel(parent)
{
    QUrl url("http://schreuderelectronics.com/osm/index.php");
    connect(
      &m_WebCtrl, SIGNAL (finished(QNetworkReply*)),
      this, SLOT (fileDownloaded(QNetworkReply*))
      );

    QNetworkRequest request(url);
    m_WebCtrl.get(request);


}

DownloadListModel::~DownloadListModel()
{
    for (QList<DownloadListItem*>::iterator item=downloadListItems.begin();
         item!=downloadListItems.end();
         ++item) {
        delete *item;
    }

    downloadListItems.clear();
}

#include <iostream>

void DownloadListModel::fileDownloaded(QNetworkReply* pReply) {
 m_DownloadedData = pReply->readAll();
 //emit a signal
 pReply->deleteLater();
 QString indexDoc(m_DownloadedData);

 QStringList links = indexDoc.split("<a href='");
 for(int i=1; i<links.size(); i++) //start at 1, to remove html header
 {
     QStringList splitLinks = links[i].split("'");
     if(splitLinks.size()<1)continue;
     QString name = splitLinks[0];
     QString size = splitLinks[1].split("</a> ")[1].split("<br/>")[0];
     QString version;
     if(splitLinks[1].split("</a> ")[1].split("<br/>").size()>1)
     {
        version = splitLinks[1].split("</a> ")[1].split("<br/>")[1];
        version.replace("CEST ","");
        size=size+" <i>"+version+"</i>";
     }
     else
     {
        version = "";
     }

     DownloadListItem* item = new DownloadListItem(name, size);
     beginInsertRows(QModelIndex(), 0,0);
     downloadListItems.append(item);
     endInsertRows();
     std::cout<<"Map name: "<<name.toLocal8Bit().data()<<std::endl;
     std::cout<<"Map size: "<<size.toLocal8Bit().data()<<std::endl;
     std::cout<<"Map version: "<<version.toLocal8Bit().data()<<std::endl;
 }
 std::cout<<"*DownloadListModel size: "<<downloadListItems.size()<<std::endl;
 //emit
 emit downloaded();


}

QVariant DownloadListModel::data(const QModelIndex &index, int role) const
{
    if(index.row() < 0 || index.row() >= downloadListItems.size()) {
        return QVariant();
    }

    DownloadListItem* item = downloadListItems.at(index.row());
    switch (role) {
    case Qt::DisplayRole:
    case NameRole:
        return item->getName();
    case SizeRole:
        return item->getSize();
    default:
        break;
    }

    return QVariant();
}

int DownloadListModel::rowCount(const QModelIndex &parent) const
{
    std::cout<<"DownloadListModel size: "<<downloadListItems.size()<<std::endl;
    return downloadListItems.size();
}

Qt::ItemFlags DownloadListModel::flags(const QModelIndex &index) const
{
    if(!index.isValid()) {
        return Qt::ItemIsEnabled;
    }

    return QAbstractListModel::flags(index) | Qt::ItemIsEnabled | Qt::ItemIsSelectable;
}

QHash<int, QByteArray> DownloadListModel::roleNames() const
{
    QHash<int, QByteArray> roles=QAbstractListModel::roleNames();

    roles[SizeRole]="size";
    roles[NameRole]="name";

    return roles;
}

QString DownloadListModel::get(int row) const
{
    return downloadListItems.at(row)->getName();
}
